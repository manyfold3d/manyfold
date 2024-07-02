class ModelFile < ApplicationRecord
  include LibraryUploader::Attachment(:attachment)

  extend Memoist

  belongs_to :model
  has_many :problems, as: :problematic, dependent: :destroy

  after_create :attach_existing_file!

  belongs_to :presupported_version, class_name: "ModelFile", optional: true
  has_one :unsupported_version, class_name: "ModelFile", foreign_key: "presupported_version_id",
    inverse_of: :presupported_version, dependent: :nullify

  validates :filename, presence: true, uniqueness: {scope: :model}
  validate :presupported_version_is_presupported
  validate :presupported_files_cannot_have_presupported_version

  default_scope { order(:filename) }
  scope :unsupported, -> { where(presupported: false) }
  scope :presupported, -> { where(presupported: true) }

  acts_as_favoritable

  SUPPORT_KEYWORDS = %w[
    presupported
    presup
    supported
    sup
    wsupports
    withsupports
  ]

  def size
    attachment.size
  rescue
    attributes["size"]
  end

  def size=(value)
    ActiveSupport::Deprecation.warn("size is now set by Shrine")
  end

  def extension
    attachment.extension
  rescue
    File.extname(filename).delete(".").downcase
  end

  def is_image?
    SupportedMimeTypes.image_extensions.include? extension
  end

  def is_3d_model?
    SupportedMimeTypes.model_extensions.include? extension
  end

  def mime_type
    Mime::Type.lookup_by_extension(extension)
  end

  def basename(include_extension: false)
    File.basename(filename, include_extension ? "" : ".*")
  end

  def name
    basename.humanize.titleize
  end

  def absolute_path
    File.join(model.absolute_path, filename)
  end

  def path_within_library
    File.join(model.path, filename)
  end

  def attach_existing_file!(refresh: true)
    return if attachment.present? || !exists_on_storage?
    attachment_attacher.set Shrine.uploaded_file(
      storage: model.library.storage_key,
      id: path_within_library,
      metadata: {
        filename: basename(include_extension: true),
        size: attributes["size"],
        mime_type: Mime::Type.lookup_by_extension(File.extname(filename).delete(".").downcase).to_s
      }
    )
    attachment_attacher.refresh_metadata! if refresh
    save!
  end

  def exists_on_storage?
    model.library.has_file?(path_within_library)
  end

  def mtime
    File.mtime(absolute_path)
  end

  def head(bytes)
    io = attachment.open
    result = io.read(bytes)
    io.close
    result
  end

  def calculate_digest
    Digest::SHA512.new.file(absolute_path).hexdigest
  rescue Errno::ENOENT
    nil
  end

  def bounding_box
    return nil unless mesh
    bbox = Mittsu::Box3.new.set_from_object(mesh)
    bbox.size.to_a
  end

  def duplicates
    return ModelFile.none if digest.nil?
    ModelFile.where(digest: digest).where.not(id: id)
  end

  def duplicate?
    duplicates.count > 0
  end

  # Used for ETag in conditional GETs
  # See https://guides.rubyonrails.org/caching_with_rails.html#conditional-get-support
  def cache_key_with_version
    digest
  end

  def delete_from_disk_and_destroy
    # Rescan any duplicates
    duplicates.each { |x| Analysis::AnalyseModelFileJob.perform_later(x.id) }
    # Remove the db record
    destroy
  end

  def set_printed_by_user(user, printed)
    if printed
      user.favorite(self, scope: :printed)
    else
      user.unfavorite(self, scope: :printed)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "digest", "filename", "id", "notes", "presupported", "size", "updated_at", "y_up", "presupported_version_id", "unsupported_version_id"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["favorited", "model", "problems"]
  end

  def mesh
    loader&.new&.load(absolute_path)
  end
  memoize :mesh

  def reattach!
    attachment_attacher.attach attachment, storage: model.library.storage_key
    save!
  end

  private

  def presupported_files_cannot_have_presupported_version
    if presupported_version && presupported
      errors.add(:presupported_version, :already_presupported)
    end
  end

  def presupported_version_is_presupported
    if presupported_version && !presupported_version.presupported
      errors.add(:presupported_version, :not_supported)
    end
  end

  def loader
    case extension
    when "stl"
      Mittsu::STLLoader
    when "obj"
      Mittsu::OBJLoader
    end
  end
end
