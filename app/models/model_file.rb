class ModelFile < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.model_file")

  include ModelFileUploader::Attachment(:attachment)
  include Listable
  include PublicIDable
  include Problematic
  include Relatable

  extend Memoist

  broadcasts_refreshes

  SPECIAL_FILES = [
    "datapackage.json"
  ]

  belongs_to :model, touch: true

  after_create :attach_existing_file!

  before_destroy :rescan_duplicates
  after_commit :reattach!, on: :update, if: :filename_previously_changed?

  has_many :related_files, through: :relationships, source_type: "ModelFile", source: "objekt"
  has_many :files_related_to_me, through: :reverse_relationships, source_type: "ModelFile", source: "subject"

  normalizes :filename, with: ->(filename) { normalize_filename(filename) }

  validates :filename, presence: true, length: {maximum: 255}, uniqueness: {scope: :model}, stable_mime_type: true, change_case_only: true

  after_commit :clear_presupported_relation, on: :update, if: :presupported_previously_changed?
  after_commit :check_derivatives!, on: :update, if: :y_up_previously_changed?

  scope :without_special, -> { where.not(filename: SPECIAL_FILES) }
  scope :unsupported, -> { where(presupported: false) }
  scope :presupported, -> { where(presupported: true) }

  # Explicitly explain serialization for MariaDB
  serialize :attachment_data, coder: CrossDbJsonSerializer

  delegate :indexable?, to: :model
  delegate :ai_indexable?, to: :model

  SUPPORT_KEYWORDS = %w[
    presupported
    presup
    supported
    sup
    wsupports
    withsupports
  ]

  def extension
    if has_attribute? :attachment_data
      attachment&.extension
    else
      # DEPRECATED: for Pre-shrine migration
      File.extname(filename).delete(".").downcase
    end
  end

  def is_image?
    SupportedMimeTypes.image_extensions.include? extension
  end

  def is_video?
    SupportedMimeTypes.video_extensions.include? extension
  end

  def is_document?
    SupportedMimeTypes.document_extensions.include? extension
  end

  def is_3d_model?
    SupportedMimeTypes.model_extensions.include? extension
  end

  def has_render?
    is_3d_model? && attachment_attacher.derivatives.key?(:render)
  end

  def mime_type
    Mime::Type.lookup_by_extension(extension)
  end

  def basename(include_extension: false)
    File.basename(filename, include_extension ? "" : ".*")
  end

  def filename_without_extension
    dirname = File.dirname(filename)
    File.join([dirname, basename(include_extension: false)].reject { |it| it == "." })
  end

  def name
    basename.humanize.careful_titleize
  end

  def path_within_library(derivative: nil)
    derivative ?
      File.join(model.path, ".manyfold", "derivatives", filename, "#{derivative}.#{extension}") :
      File.join(model.path, filename)
  end

  def attach_existing_file!(refresh: true, skip_validations: false)
    return if attachment.present? || !exists_on_storage?
    attachment_attacher.set ModelFileUploader.uploaded_file(
      storage: model.library.storage_key,
      id: path_within_library,
      metadata: {
        filename: basename(include_extension: true),
        size: attributes["size"],
        mime_type: Mime::Type.lookup_by_extension(File.extname(filename).delete(".").downcase).to_s
      }
    )
    attachment_attacher.refresh_metadata! if refresh
    save!(validate: !skip_validations)
  end

  def exists_on_storage?
    model.library.has_file? path_within_library
  end

  def file_last_modified
    model.library.file_last_modified path_within_library
  end

  def head(bytes)
    io = attachment.open
    result = io.read(bytes)
    io.close
    result
  end

  def dimensions
    bbox = attachment.metadata.dig("object", "bounding_box")
    return nil unless bbox
    bbox = Mittsu::Box3.new.set_from_points([
      Mittsu::Vector3.new(bbox.dig("minimum", "x"), bbox.dig("minimum", "y"), bbox.dig("minimum", "z")),
      Mittsu::Vector3.new(bbox.dig("maximum", "x"), bbox.dig("maximum", "y"), bbox.dig("maximum", "z"))
    ])
    bbox.size
  end

  def planar?
    i = dimensions.to_a.index { |it| it.zero? }
    i ? [:x, :y, :z].at(i) : nil
  end

  def duplicates
    return ModelFile.none if digest.nil? # rubocop:todo Pundit/UsePolicyScope
    ModelFile.where(digest: digest).where.not(id: id) # rubocop:todo Pundit/UsePolicyScope
  end

  def duplicate?
    size && size > 0 && duplicates.exists? && !is_document?
  end

  # Used for ETag in conditional GETs
  # See https://guides.rubyonrails.org/caching_with_rails.html#conditional-get-support
  def cache_key_with_version
    digest
  end

  def scene
    Shrine.with_file(attachment.open) do |it|
      scene = Assimp.import_file(it.path)
      scene.apply_post_processing(Assimp::PostProcessSteps[
        :JoinIdenticalVertices,
        :Triangulate
      ])
    end
  end

  def reattach!
    if attachment.id != path_within_library || attachment.storage_key != model.library.storage_key
      old_path = attachment.id
      old_storage = attachment.storage
      # Reattach
      attachment_attacher.attach attachment, storage: model.library.storage_key
      # Remove previous file
      old_storage.delete old_path
      save!
    end
  end

  def name_and_filename
    "#{name} (#{filename})"
  end

  def convert_later(format, delay: 0.seconds)
    Analysis::FileConversionJob.set(wait: delay).perform_later(id, format.to_sym)
  end

  def convertable?(to: nil)
    return false unless FileHandlers::Assimp.can_load? mime_type
    to.nil? || FileHandlers::Assimp.can_save?(to)
  end

  def delete_from_disk_and_destroy
    model.library.storage.delete path_within_library
    destroy
  end

  def analyse_later(delay: 5.seconds)
    Analysis::AnalyseModelFileJob.set(wait: delay).perform_later(id)
  end

  def analyse_geometry_later(delay: 0.seconds)
    Analysis::GeometricAnalysisJob.set(wait: delay).perform_later(id)
  end

  def parse_metadata_later(delay: 0.seconds)
    Scan::ModelFile::ParseMetadataJob.set(wait: delay).perform_later(id)
  end

  def up_direction
    y_up ? "+y" : "+z"
  end

  def mtime
    attachment&.mtime.present? ? Time.zone.parse(attachment.mtime) : updated_at
  rescue NoMethodError
    updated_at
  end

  def ctime
    attachment&.ctime.present? ? Time.zone.parse(attachment.ctime) : updated_at
  rescue NoMethodError
    created_at
  end

  def update_from_url!(url:)
    save! if attachment_attacher.assign_remote_url(
      url,
      downloader: {
        headers: {
          "If-None-Match" => attachment&.metadata&.dig("remote_etag"),
          "If-Modified-Since" => attachment&.metadata&.dig("remote_last_modified")
        }.compact
      }
    )
  end

  def refresh_metadata!
    ApplicationRecord.no_touching do
      attachment_attacher&.refresh_metadata!
      save(touch: false, validate: false)
    end
  end

  def check_derivatives!
    ApplicationRecord.no_touching do
      regen = attachment_derivatives.empty?
      # Clear out missing derivatives
      attachment_derivatives.each do |k, v|
        unless model.library.has_file?(v.id)
          attachment_attacher&.remove_derivative(k)
          regen = true
        end
      end
      if regen
        attachment_attacher&.create_derivatives
        save!(validate: false, touch: false)
      end
    end
  end

  def unsupported_version
    relationships.where(predicate: "supported_version_of").first&.objekt
  end

  def presupported_version
    reverse_relationships.where(predicate: "supported_version_of").first&.subject
  end

  def alternative_formats
    files_related_to_me.where("relationships.predicate" => "alternative_format_of")
  end

  def presupported_version=(file)
    clear_presupported_relation and return if file.nil?
    return unless !presupported && file.presupported
    if file != presupported_version
      reverse_relationships.where(predicate: "supported_version_of").create_with(subject: file).first_or_create!.update(subject: file)
    end
  end

  private

  def rescan_duplicates
    duplicates.each { |it| it.analyse_later }
  end

  def clear_presupported_relation
    relationships.where(predicate: "supported_version_of").destroy_all
  end

  class << self
    private

    def normalize_filename(filename)
      parts = filename.split(File::SEPARATOR).compact_blank
      parts.delete("..")
      parts.delete(".")
      File.join(parts.map { |it| Zaru.sanitize!(it) })
    end
  end
end
