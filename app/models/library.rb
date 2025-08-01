class Library < ApplicationRecord
  extend Memoist
  include PublicIDable
  include Problematic

  STORAGE_SERVICES = [
    "filesystem",
    "s3"
  ]

  has_many :models, dependent: :destroy
  has_many :model_files, through: :models
  serialize :tag_regex, type: Array, coder: YAML
  after_initialize :init
  before_validation :ensure_path_case_is_correct
  after_destroy :reset_default_library
  after_commit :register_storage, on: :create

  normalizes :path, with: ->(path) do
    Pathname.new(path).realpath.to_s
  rescue Errno::ENOENT, Errno::EACCES # carry on, we validate these later
    path
  end

  validates :storage_service, presence: true, inclusion: STORAGE_SERVICES
  validates :path,
    presence: true,
    uniqueness: true,
    safe_path: true,
    writable: true,
    disjoint_library_folder: true,
    if: -> { storage_service == "filesystem" }

  validates :s3_bucket, presence: true, if: -> { storage_service == "s3" }
  validates :s3_region, presence: true, if: -> { storage_service == "s3" }
  validates :s3_access_key_id, presence: true, if: -> { storage_service == "s3" }
  validates :s3_secret_access_key, presence: true, if: -> { storage_service == "s3" }

  default_scope { order(:name) }

  def name
    self[:name] || (path ? File.basename(path) : "")
  end

  def init
    self.name = nil if name == ""
  end

  # Backwards compatibility for use during migrations
  def storage_service
    attributes["storage_service"] || "filesystem"
  end

  def storage_exists?
    case storage_service
    when "filesystem"
      Dir.exist?(path)
    when "s3"
      storage.bucket.exists?
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end

  def free_space
    case storage_service
    when "filesystem"
      stat = Sys::Filesystem.stat(path)
      stat.bytes_available
    when "s3"
      nil
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end

  def storage_key
    :"library_#{id}"
  end

  def storage_origin
    case storage_service
    when "s3"
      URI.parse(storage.presign(nil)[:url]).origin
    end
  end
  memoize :storage_origin

  def storage
    case storage_service
    when "filesystem"
      Shrine::Storage::FileSystem.new(path)
    when "s3"
      Shrine::Storage::S3.new(
        endpoint: s3_endpoint,
        bucket: s3_bucket,
        region: s3_region,
        access_key_id: s3_access_key_id,
        secret_access_key: s3_secret_access_key,
        force_path_style: s3_endpoint.present? && s3_path_style,
        use_accelerate_endpoint: s3_endpoint.blank?
      )
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end
  memoize :storage

  def register_storage
    LibraryUploader.storages[storage_key] = storage
  end

  def self.register_all_storage
    find_each(&:register_storage)
  rescue ActiveRecord::StatementInvalid, NameError
    nil # migrations probably haven't run yet to create library table
  end

  def list_files(pattern, flags = 0)
    files = case storage_service
    when "filesystem"
      Dir.glob(pattern, flags, base: path).filter { |it| File.file?(File.join(path, it)) }
    when "s3"
      keys = []
      pattern_array = [pattern].flatten
      storage.bucket.objects.each do |object|
        keys << object.key if pattern_array.any? { |p| File.fnmatch?(p, object.key) }
      end
      keys
    else
      raise "Invalid storage service: #{storage_service}"
    end
    # Filter out files that should be ignored
    files.uniq.reject { |str| SiteSettings.ignored_file?(str) }
  end

  def has_file?(path)
    storage.exists?(path)
  end

  def has_folder?(path)
    case storage_service
    when "s3"
      storage.bucket.objects(prefix: path).count > 0
    else
      storage.exists?(path)
    end
  end

  def file_last_modified(file)
    case storage_service
    when "filesystem"
      File.mtime(File.join(path, file))
    when "s3"
      storage.bucket.object(file).last_modified
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end

  def create_path_if_not_on_disk=(val)
    if val == "1" && storage_service == "filesystem"
      begin
        FileUtils.makedirs(path)
      rescue Errno::EROFS, Errno::EACCES
        errors.add(:path, :non_writable)
      end
    end
  end

  def self.default
    Library.find_by(id: SiteSettings.default_library) || Library.first
  end

  def default?
    SiteSettings.default_library == id
  end

  def make_default
    SiteSettings.default_library = id
  end

  def reset_default_library
    new_default = Library.where.not(id: id).first # rubocop:disable Pundit/UsePolicyScope
    new_default ? new_default.make_default : SiteSettings.default_library = nil
  end

  def detect_filesystem_changes_later(delay: 0.seconds)
    Scan::Library::DetectFilesystemChangesJob.set(wait: delay).perform_later(id)
  end

  def create_model_from_path_later(path, delay: 0.seconds)
    Scan::Library::CreateModelFromPathJob.set(wait: delay).perform_later(id, path)
  end

  private

  def ensure_path_case_is_correct
    # On case-preserving-and-insensitive filesystems (i.e. macOS)
    # if you get the case wrong, the library can be created, but then
    # models will get the wrong paths. This method makes sure that the
    # case is stored in the canonical form that the OS will give us back
    # in globs
    if storage_service == "filesystem" && path
      normalised = Dir.glob(path).first
      self.path = normalised if normalised
    end
  end
end
