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
  include Indexable
  include FaspClient::DataSharing::Lifecycle

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
  fasp_share_lifecycle category: "account", uri_method: :fasp_uri, only_if: :public_and_indexable?

  def fasp_uri
    federails_actor&.federated_url
  end

  scope :recent, -> { order(created_at: :desc) }

  belongs_to :library
  belongs_to :creator, optional: true
  belongs_to :collection, optional: true
  belongs_to :preview_file, class_name: "ModelFile", optional: true
  has_many :model_files, dependent: :destroy
  acts_as_taggable_on :tags

  accepts_nested_attributes_for :creator

  before_validation :strip_separators_from_path, if: :path_changed?
  before_validation :publish_creator, if: :will_be_public?
  before_validation :normalize_license, if: -> { respond_to? :license }
  # In Rails 7.1 we will be able to do this instead:
  # normalizes :license, with: -> license { license.blank? ? nil : license }

  after_create_commit :post_creation_activity
  after_create :pregenerate_downloads
  before_update :move_files, if: :need_to_move_files?
  after_update_commit :post_update_activity
  after_update :pregenerate_downloads, if: :was_changed?
  after_save :write_datapackage_later, if: :was_changed?
  after_commit :check_for_problems_later, on: :update

  validates :name, presence: true, on: [:create, :update, :single_upload]
  validates :path, presence: true, uniqueness: {scope: :library}, on: [:create, :update]
  validate :check_for_submodels, on: :update, if: :need_to_move_files?
  validate :destination_is_vacant, on: :update, if: :need_to_move_files?
  validates :license, spdx: true, allow_nil: true, if: -> { respond_to? :license }
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}, if: -> { respond_to? :public_id }, on: [:create, :update]

  validate :validate_publishable

  scoped_search on: [:name, :caption]
  scoped_search on: :notes, aliases: [:description], only_explicit: true
  scoped_search relation: :library, on: :name, rename: :library, only_explicit: true, default_operator: :eq
  scoped_search relation: :creator, on: :name, rename: :creator
  scoped_search relation: :collection, on: :name, rename: :collection
  scoped_search relation: :tags, on: :name, default_operator: :eq, rename: :tag
  scoped_search relation: :model_files, on: :filename, rename: :filename, only_explicit: true
  scoped_search on: :path, only_explicit: true

  def parents
    Pathname.new(path).parent.descend.filter_map do |path|
      library.models.find_by(path: path.to_s)
    end
  end
  memoize :parents

  def was_changed?
    !previous_changes.empty?
  end

  def self.common_root(*models)
    # If there are different libraries, there is no common root
    return nil unless models.map(&:library_id).uniq.one?
    # Get each path, split, and working from the front, find the common elements

    first, *remainder = models.map { |it| it.path.split(File::SEPARATOR).without(".") }
    parts = first.zip(*remainder)
    common = parts.map { |it| (it.uniq.length == 1) ? it.first : nil }
    common = common.first(common.index(nil) || 99999)
    common.empty? ? nil : File.join(common)
  end

  def disjoint?(other)
    Model.common_root(self, other).nil?
  end

  def contains?(other)
    Model.common_root(self, other) == path
  end

  def adopt_file(file, path_prefix: nil)
    # Work out the new filename
    new_filename = path_prefix ? File.join(path_prefix, file.filename) : file.filename
    # If there's an identical file already there...
    existing_file = model_files.find_by(filename: new_filename)
    if file.digest && file.digest == existing_file&.digest
      file.problems.destroy_all # Remove associated problems for this file manually
      file.delete # Don't run callbacks, just remove the database record
      return
    elsif existing_file
      # Otherwise, make sure the name is distinct by adding the digest to the end if there's a clash
      new_filename = "#{File.basename(new_filename, ".*")}_#{file.digest.first(6)}#{File.extname(new_filename)}"
    end
    # Adopt the file
    file.update(
      filename: new_filename,
      model: self
    )
    file.reattach!
  end

  def merge!(*models)
    # If we've got one argument and it's enumerable, use it directly
    models = models[0] if models.length == 1 && models[0].is_a?(Enumerable)
    # Go through the list
    models.each do |other|
      # Work out path to the other target from here
      relative_path = contains?(other) ? Pathname.new(other.path).relative_path_from(Pathname.new(path)) : nil
      # Remove datapackage
      other.datapackage&.destroy
      # Move files
      other.model_files.each { |it| adopt_file(it, path_prefix: relative_path) }
      check_for_problems_later
      # Merge metadata
      self.creator ||= other.creator
      self.collection ||= other.collection
      self.license ||= other.license
      self.caption ||= other.caption
      self.notes ||= other.notes
      self.sensitive ||= other.sensitive
      tag_list.add(*other.tag_list)
      self.links_attributes = other.links.map { |it| {url: it.url} }
      save!
      # Destroy the other model
      other.reload
      other.destroy
    end
  end

  def create_or_update_file_from_url(url:, filename:)
    uri = URI.parse(url)
    file = model_files.find_or_create_by(filename: filename)
    file.update_from_url!(url: uri.to_s)
    file
  rescue URI::InvalidURIError
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

  def self.create_from(other, link_preview_file: false, name: nil, path: nil)
    new_model = other.dup
    new_model.update(
      path: path,
      name: name || "Copy of #{other.name}",
      public_id: nil,
      tags: other.tags,
      preview_file: link_preview_file ? other.preview_file : nil
    )
    path ? new_model.save! : new_model.organize!
    # Wipe permissions and copy from old model
    new_model.caber_relations.delete_all
    new_model.update!(
      caber_relations_attributes: other.caber_relations.all.map { |it| {permission: it.permission, subject: it.subject} }
    )
    new_model
  end

  def split!(files: [])
    preview_file_will_move = files.include?(preview_file)
    new_model = Model.create_from(self, link_preview_file: preview_file_will_move)
    # Clear preview file if it was moved
    update!(preview_file: nil) if preview_file_will_move
    # Move files
    files.each { |it| new_model.adopt_file(it) }
    # Done!
    new_model
  end

  def has_supported_and_unsupported?
    model_files.exists?(presupported: true) &&
      model_files.exists?(presupported: false)
  end

  def file_extensions
    model_files.map(&:extension).uniq
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

  def pregenerate_downloads(delay: 10.minutes, queue: nil)
    # By default, give 10 minutes' grace for followup changes before we pregenerate the download
    # Other scan jobs could be running, which might take some time.
    # This is brittle, and we need a better way to say "this model is done changing for a while"
    return unless SiteSettings.pregenerate_downloads

    download_types = [nil]
    download_types += ["supported", "unsupported"] if has_supported_and_unsupported?
    download_types += file_extensions.excluding("json")
    download_types.each do |selection|
      ArchiveDownloadService.new(model: self, selection: selection).prepare(delay: delay, queue: queue)
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
    Activity::ModelPublishedJob.set(wait: 5.seconds).perform_later(id) if public?
  end

  def post_update_activity
    if creator_previously_changed? && creator&.public?
      Activity::ModelPublishedJob.set(wait: 5.seconds).perform_later(id)
    elsif collection_previously_changed? && collection&.public?
      Activity::ModelCollectedJob.set(wait: 5.seconds).perform_later(id, collection.id)
    elsif just_became_public?
      Activity::ModelPublishedJob.set(wait: 5.seconds).perform_later(id)
    elsif public? && noteworthy_change?
      Activity::ModelUpdatedJob.set(wait: 5.seconds).perform_later(id)
    end
  end

  def noteworthy_change?
    # Exclude internal fields, they're not interesting enough to post comments for
    !previous_changes.keys.without([
      "id",
      "path",
      "library_id",
      "created_at",
      "updated_at",
      "preview_file_id",
      "slug",
      "public_id",
      "name_lower"
    ]).empty?
  end

  def validate_publishable
    # If the model will be public
    return unless will_be_public?
    # Check required fields
    errors.add :license, :blank if license.nil?
    errors.add :creator, :blank if creator.nil?
    errors.add :creator, :private if creator && !creator.public?
  end

  def publish_creator
    creator&.update!(caber_relations_attributes: [{permission: "view", subject: nil}]) unless creator&.public?
  end
end
