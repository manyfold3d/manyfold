class Model < ApplicationRecord
  extend Memoist
  include PathBuilder
  include Followable
  include CaberObject
  include Linkable
  include Sluggable
  include PublicIDable
  include Commentable
  include Problematic

  broadcasts_refreshes

  acts_as_federails_actor(
    username_field: :public_id,
    name_field: :name,
    profile_url_method: :url_for,
    # We use the Service actor type purely so Mastodon doesn't ignore the actor.
    # Actual type is differentiated with f3di:concreteType == "3DModel".
    # Ideally this would be a Document: https://www.w3.org/TR/activitystreams-vocabulary/#dfn-document
    # Hopefully at some point this can change, if Mastodon starts allowing other actor types
    # See https://github.com/mastodon/mastodon/issues/22322
    actor_type: "Service"
  )

  scope :recent, -> { order(created_at: :desc) }

  belongs_to :library
  belongs_to :creator, optional: true
  belongs_to :collection, optional: true
  belongs_to :preview_file, class_name: "ModelFile", optional: true
  has_many :model_files, dependent: :destroy
  acts_as_taggable_on :tags

  before_validation :strip_separators_from_path, if: :path_changed?

  before_validation :normalize_license
  # In Rails 7.1 we will be able to do this instead:
  # normalizes :license, with: -> license { license.blank? ? nil : license }

  after_create :post_creation_activity
  after_create :pregenerate_downloads
  before_update :move_files, if: :need_to_move_files?
  after_update :post_update_activity, if: :was_changed?
  after_update :pregenerate_downloads, if: :was_changed?
  after_save :write_datapackage_later, if: :was_changed?
  after_commit :check_for_problems_later, on: :update

  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}
  validate :check_for_submodels, on: :update, if: :need_to_move_files?
  validate :destination_is_vacant, on: :update, if: :need_to_move_files?
  validates :license, spdx: true, allow_nil: true
  validates :public_id, multimodel_uniqueness: {case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}

  scoped_search on: [:name, :caption]
  scoped_search on: :notes, aliases: [:description], only_explicit: true
  scoped_search relation: :creator, on: :name, rename: :creator
  scoped_search relation: :collection, on: :name, rename: :collection
  scoped_search relation: :tags, on: :name, default_operator: :eq, rename: :tag
  scoped_search relation: :model_files, on: :filename, rename: :filename, only_explicit: true

  def parents
    Pathname.new(path).parent.descend.filter_map do |path|
      library.models.find_by(path: path.to_s)
    end
  end
  memoize :parents

  def was_changed?
    !previous_changes.empty?
  end

  def merge_into!(target)
    return unless target

    # Work out path to this model from the target
    relative_path = Pathname.new(path).relative_path_from(Pathname.new(target.path))
    # Remove datapackage
    datapackage&.destroy
    # Move files
    model_files.each do |f|
      new_filename = File.join(relative_path, f.filename)
      if target.model_files.exists?(filename: new_filename)
        f.problems.destroy_all # Remove associated problems for this file manually
        f.delete # Don't run callbacks, just remove the database record
      else
        f.update(
          filename: new_filename,
          model: target
        )
      end
    end
    target.check_for_problems_later
    # Destroy this model
    reload
    destroy
  end

  def delete_from_disk_and_destroy
    # Remove all presupported_version relationships first, they get in the way
    # This will go away later when we do proper file relationships rather than linking the tables directly
    model_files.update_all(presupported_version_id: nil) # rubocop:disable Rails/SkipsModelValidations
    # Trigger deletion for each file separately, to make sure cleanup happens
    model_files.each { |f| f.delete_from_disk_and_destroy }
    # Remove tags first - sometimes this causes problems if we don't do it beforehand
    update!(tags: [])
    # Delete directory corresponding to model
    library.storage.delete_prefixed(path)
    # Remove from DB
    destroy
  end

  def contained_models
    previous_library.models.where(
      Model.arel_table[:path].matches(
        Model.sanitize_sql_like(previous_path) + "/%",
        "\\"
      )
    )
  end

  def contains_other_models?
    contained_models.exists?
  end

  def needs_organizing?
    formatted_path != path
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "id", "public_id", "library_id", "name", "notes", "path", "slug", "updated_at", "license_cont", "license"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["base_tags", "collection", "creator", "library", "links", "model_files", "preview_file", "problems", "tag_taggings", "taggings", "tags"]
  end

  def new?
    tags.where(name: SiteSettings.model_tags_auto_tag_new).any?
  end

  def valid_preview_files
    model_files.select { |it| it.is_image? || it.is_renderable? }
  end

  def image_files
    model_files.select(&:is_image?)
  end

  def three_d_files
    model_files.select(&:is_3d_model?)
  end

  def exists_on_storage?
    library.has_folder?(path)
  end

  def organize!
    autoupdate_path
    save!
  end

  def split!(files: [])
    new_model = dup
    new_model.name = "Copy of #{name}"
    new_model.public_id = nil
    new_model.tags = tags
    new_model.organize!
    # Move files
    files.each do |file|
      file.update!(model: new_model)
      file.reattach!
    end
    # Clear preview file appropriately
    if files.include?(preview_file)
      update!(preview_file: nil)
    else
      new_model.update!(preview_file: nil)
    end
    # Done!
    new_model
  end

  def has_supported_and_unsupported?
    model_files.where(presupported: true).count > 0 &&
      model_files.where(presupported: false).count > 0
  end

  def file_extensions
    model_files.map(&:extension).uniq
  end

  def merge_all_children!
    contained_models.each do |child|
      child.merge_into! self
    end
  end

  def size_on_disk
    model_files.pluck(:size).compact.sum
  end

  def to_activitypub_object
    ActivityPub::ModelSerializer.new(self).serialize
  end

  def add_new_files_later(include_all_subfolders: false, delay: 0.seconds)
    Scan::Model::AddNewFilesJob.set(wait: delay).perform_later(id, include_all_subfolders: include_all_subfolders)
  end

  def check_later(delay: 0.seconds)
    Scan::CheckModelJob.set(wait: delay).perform_later(id)
  end

  def check_for_problems_later(delay: 5.seconds)
    Scan::Model::CheckForProblemsJob.set(wait: delay).perform_later(id)
  end

  def organize_later(delay: 5.seconds)
    OrganizeModelJob.set(wait: delay).perform_later(id)
  end

  def write_datapackage_later(delay: 1.second)
    UpdateDatapackageJob.set(wait: delay).perform_later(id)
  end

  def parse_metadata_later(delay: 0.seconds)
    Scan::Model::ParseMetadataJob.set(wait: delay).perform_later(id)
  end

  def datapackage
    model_files.find_by(filename: "datapackage.json")
  end

  def datapackage_content
    JSON.parse(datapackage.attachment.read) unless datapackage.nil?
  rescue Shrine::FileNotFound
  end

  def pregenerate_downloads(delay: 10.minutes)
    # By default, give 10 minutes' grace for followup changes before we pregenerate the download
    # Other scan jobs could be running, which might take some time.
    # This is brittle, and we need a better way to say "this model is done changing for a while"
    return unless SiteSettings.pregenerate_downloads

    download_types = [nil]
    download_types += ["supported", "unsupported"] if has_supported_and_unsupported?
    download_types += file_extensions.excluding("json")
    download_types.each do |selection|
      ArchiveDownloadService.new(model: self, selection: selection).prepare(delay: delay)
    end
  end

  private

  def normalize_license
    self.license = nil if license.blank?
  end

  def strip_separators_from_path
    self.path = path&.trim_path_separators
  end

  def previous_library
    library_id_changed? ? Library.find_by(id: library_id_was) : library
  end

  def previous_path
    path_changed? ? path_was : path
  end

  def need_to_move_files?
    library_id_changed? ||
      (path_changed? &&
        (previous_path.trim_path_separators != path.trim_path_separators)
      )
  end

  def autoupdate_path
    self.path = formatted_path
  end

  def check_for_submodels
    if contains_other_models?
      errors.add(library_id_changed? ? :library : :path, :nested)
    end
  end

  def destination_is_vacant
    if exists_on_storage? && need_to_move_files?
      errors.add(:path, :destination_exists)
    end
  end

  def move_files
    # Move all the files
    model_files.each(&:reattach!)
    # Remove the old folder if it's still there
    previous_library.storage.delete_prefixed(previous_path)
  end

  def post_creation_activity
    if creator.present?
      Activity::CreatorAddedModelJob.set(wait: 5.seconds).perform_later(id)
    end
  end

  def post_update_activity
    if creator_previously_changed?
      Activity::CreatorAddedModelJob.set(wait: 5.seconds).perform_later(id)
    end
  end
end
