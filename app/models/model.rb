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
  include Listable
  include FaspClient::DataSharing::Lifecycle

  broadcasts_refreshes

  # Transient flags to suppress expensive callback cascades (bulk deletes, scan batches).
  # Prefer these over Current.* — jobs/services set flags on the record before save.
  attr_accessor :skip_problem_check, :suppress_problem_checks, :suppress_announce

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

  # Preview is an image file (jpg/png/…) — same rule as FilterService#filter_by_has_image.
  # EXISTS + filename_lower does a PK lookup per model.preview_file_id instead of scanning
  # every model_file via IN (SELECT id … LOWER(filename) LIKE …) (INIT-009/SPEC-005).
  scope :with_image_preview, -> {
    exts = SupportedMimeTypes.image_extensions.map(&:downcase).uniq
    if exts.empty?
      none
    else
      where(ModelFile.image_preview_exists_sql)
    end
  }

  belongs_to :library
  belongs_to :creator, optional: true
  belongs_to :collection, optional: true
  belongs_to :preview_file, class_name: "ModelFile", optional: true
  has_many :model_files, dependent: :destroy
  has_many :archive_entries, through: :model_files
  has_many :merge_histories, foreign_key: :target_model_id, dependent: :destroy, inverse_of: :target_model
  has_many :sliced_artifacts, dependent: :destroy
  has_many :print_jobs, dependent: :nullify
  has_many :print_curation_notes, dependent: :destroy
  acts_as_taggable_on :tags

  accepts_nested_attributes_for :creator

  before_validation :strip_separators_from_path, if: :path_changed?
  # Do not auto-publish creators — validate_publishable requires an already-public creator.
  before_validation :normalize_license, if: -> { respond_to? :license }

  after_create_commit :post_creation_activity
  after_create :pregenerate_downloads
  # Storage moves are explicit via Model::Update / Model::MoveFiles (no before_update).
  after_update_commit :post_update_activity
  after_update :pregenerate_downloads, if: :was_changed?
  after_commit :check_for_problems_later, on: :update, unless: :suppress_problem_checks?

  validates :name, presence: true, on: [:create, :update, :single_upload]
  validates :path, presence: true, uniqueness: {scope: :library}, on: [:create, :update]
  validate :check_for_submodels, on: :update, if: :needs_storage_move?
  validate :destination_is_vacant, on: :update, if: :needs_storage_move?
  validates :license, spdx: true, allow_nil: true, if: -> { respond_to? :license }
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}, if: -> { respond_to? :public_id }, on: [:create, :update]

  validate :validate_publishable

  scoped_search on: [:name, :caption]
  scoped_search on: :notes, aliases: [:description], only_explicit: true
  scoped_search relation: :library, on: :name, rename: :library, only_explicit: true, default_operator: :eq
  scoped_search relation: :creator, on: :name, rename: :creator
  scoped_search relation: :collection, on: :name, rename: :collection
  # ILIKE substring in free-text (same as name); explicit tag=foo still uses =.
  scoped_search relation: :tags, on: :name, rename: :tag
  scoped_search relation: :model_files, on: :filename, rename: :filename, only_explicit: true
  # Folder paths often carry character/set names — include in bare q=.
  scoped_search on: :path
  # Files inside zip/7z/rar (after archive scan) — bare q= and inside~name.
  scoped_search relation: :archive_entries, on: :pathname, rename: :inside

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
    new_filename = path_prefix ? File.join(path_prefix, file.filename) : file.filename
    existing_file = model_files.find_by(filename: new_filename)

    if existing_file
      if file.digest.present? && file.digest == existing_file.digest
        # Identical content at same path -- deduplicate (don't delete; let source destroy handle it)
        return {status: :deduplicated, existing_file_id: existing_file.id}
      else
        # Name collision, different content -- disambiguate
        suffix = file.digest.presence || SecureRandom.hex(6)
        new_filename = "#{File.basename(new_filename, ".*")}_#{suffix}#{File.extname(new_filename)}"
      end
    end

    # INIT-002/SPEC-003: persist SQL only. NFS reattach is ModelFile after_commit
    # so a ROLLBACK cannot leave bytes at the new prefix.
    file.update!(filename: new_filename, model: self)
    {status: :adopted}
  end

  def merge!(*models)
    Model::Merge.call(self, *models)
  end

  UNMERGE_WINDOW = 30.days

  def unmerge!(merge_history, skip_problem_checks: true)
    Model::Unmerge.call(self, merge_history, skip_problem_checks: skip_problem_checks)
  end

  # Used by Model::Unmerge to copy physical bytes when restoring a deduplicated file.
  def copy_file_to_model_file_for_unmerge(source_file, dest_file)
    copy_file_to_model_file(source_file, dest_file)
  end

  def create_or_update_file_from_url(url:, filename:)
    uri = URI.parse(url)
    file = model_files.find_or_create_by(filename: filename)
    file.update_from_url!(url: uri.to_s)
    file
  rescue URI::InvalidURIError
  end

  def delete_from_disk_and_destroy
    Model::Delete.call(self)
  end

  def delete_from_disk_and_destroy_without_cascade
    Model::Delete.delete_without_cascade(self)
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
    raise ActiveRecord::RecordInvalid, self unless Model::Update.call(self, {path: formatted_path})

    self
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
    # Prevent after_create_commit :set_permissions_from_preset from adding default view permission on commit
    new_model.instance_variable_set(:@permission_preset, nil)
    new_model
  end

  def split!(files: [])
    preview_file_will_move = files.include?(preview_file)
    new_model = nil
    ActiveRecord::Base.transaction do
      new_model = Model.create_from(self, link_preview_file: preview_file_will_move)
      # Clear preview file if it was moved
      update!(preview_file: nil) if preview_file_will_move
      # Move files
      files.each { |it| new_model.adopt_file(it) }
    end
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

  def add_new_files_later(include_all_subfolders: false, delay: 0.seconds, scan_batch_id: nil)
    Scan::Model::AddNewFilesJob.set(wait: delay).perform_later(
      id,
      include_all_subfolders: include_all_subfolders,
      scan_batch_id: scan_batch_id
    )
  end

  # Scan batch ID is only in job arguments and Current (ActiveSupport::CurrentAttributes).
  # It is not stored on the model; it is used for cache-key idempotency in FinalizeScanBatchJob.
  SCAN_STALE_THRESHOLD = 10.minutes

  def scan_stale?
    scan_started_at.present? && scan_started_at < SCAN_STALE_THRESHOLD.ago
  end

  def check_later(delay: 0.seconds, scan_batch_id: nil)
    scan_batch_id ||= SecureRandom.uuid
    if has_attribute?(:scan_started_at)
      update_column(:scan_started_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
    Scan::CheckModelJob.set(wait: delay).perform_later(id, scan_batch_id: scan_batch_id)
  end

  def scan_archives_later(delay: 0.seconds)
    model_files.find_each do |file|
      file.scan_archive_later(delay: delay) if file.is_archive?
    end
  end

  def check_for_problems_later(delay: 5.seconds)
    return if suppress_problem_checks?

    # Debounce: avoid enqueuing multiple identical checks in quick succession.
    begin
      key = "manyfold:problems:debounce:model:#{id}"
      wrote = Rails.cache.write(key, true, expires_in: delay + 30.seconds, unless_exist: true)
      return unless wrote
    rescue ArgumentError, NoMethodError
      # Cache store doesn't support `unless_exist`; fall back to job uniqueness.
    end

    # INIT-005/SPEC-002: uniqueness Redlock must not fail interactive update HTTP (ADR 0004).
    begin
      Scan::Model::CheckForProblemsJob.set(wait: delay).perform_later(id)
    rescue Redlock::LockAcquisitionError, RedisClient::ConnectionError, RedisClient::CannotConnectError => e
      Rails.logger.warn(
        "[Model#check_for_problems_later] skipped uniqueness lock failure " \
        "model_id=#{id} error_class=#{e.class.name}"
      )
    end
  end

  def organize_later(delay: 5.seconds)
    OrganizeModelJob.set(wait: delay).perform_later(id)
  end

  def parse_metadata_later(delay: 0.seconds, scan_batch_id: nil)
    Scan::Model::ParseMetadataJob.set(wait: delay).perform_later(id, scan_batch_id: scan_batch_id)
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

  # Used by Model::Merge to place files from a source model under this target.
  def compute_merge_prefix(other)
    if contains?(other)
      Pathname.new(other.path).relative_path_from(Pathname.new(path)).to_s
    elsif other.library_id == library_id && Model.common_root(self, other)
      Pathname.new(other.path).relative_path_from(Pathname.new(path)).to_s
    else
      File.basename(other.path)
    end
  end

  # Public API for Model::Update — capture dirty state before save.
  def needs_storage_move?
    library_id_changed? ||
      (path_changed? &&
        (previous_path.trim_path_separators != path.trim_path_separators)
      )
  end

  def storage_move_from_library
    previous_library
  end

  def storage_move_from_path
    previous_path
  end

  def suppress_problem_checks?
    !!(skip_problem_check || suppress_problem_checks)
  end

  def suppress_federation_announce?
    !!suppress_announce
  end

  private

  # Copy physical file from source_file (e.g. target's file) to dest_file (e.g. restored model's new record).
  def copy_file_to_model_file(source_file, dest_file)
    dest_path = dest_file.path_within_library
    dest_storage = dest_file.model.library.storage
    source_file.attachment.download do |io|
      dest_storage.upload(io, dest_path)
    end
    dest_file.attach_existing_file!
  end

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
    needs_storage_move?
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
    if exists_on_storage? && needs_storage_move?
      errors.add(:path, :destination_exists)
    end
  end

  def post_creation_activity
    Federation::Announce.model_created(self)
  end

  def post_update_activity
    Federation::Announce.model_updated(self)
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
    # Enforce publish requirements only when becoming public — not on every
    # save of an already-public model (delete tag clears, metadata edits, etc.).
    return unless becoming_public?
    # Check required fields
    errors.add :license, :blank if license.nil?
    errors.add :creator, :blank if creator.nil?
    errors.add :creator, :private if creator && !creator.public?
  end
end
