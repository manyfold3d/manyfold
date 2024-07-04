require "shellwords"

class Library < ApplicationRecord
  STORAGE_SERVICES = [
    "filesystem"
  ]

  has_many :models, dependent: :destroy
  has_many :model_files, through: :models
  has_many :problems, as: :problematic, dependent: :destroy
  serialize :tag_regex, type: Array
  after_initialize :init
  before_validation :ensure_path_case_is_correct
  after_save :register_storage

  validates :path, presence: true, uniqueness: true, existing_path: true
  validates :storage_service, presence: true, inclusion: STORAGE_SERVICES

  default_scope { order(:path) }

  def name
    self[:name] || (path ? File.basename(path) : "")
  end

  def init
    self.name = nil if name == ""
  end

  def storage_exists?
    case storage_service
    when "filesystem"
      Dir.exist?(path)
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end

  def all_tags
    models.includes(:tags).map(&:tags).flatten.uniq.sort_by(&:name)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["caption", "created_at", "icon", "id", "name", "notes", "path", "tag_regex", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["model_files", "models", "problems"]
  end

  def free_space
    stat = Sys::Filesystem.stat(path)
    stat.bytes_available
  end

  def storage_key
    "library_#{id}"
  end

  def storage
    case storage_service
    when "filesystem"
      Shrine::Storage::FileSystem.new(path)
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end

  def register_storage
    Shrine.storages[storage_key] = storage
  end

  def self.register_all_storage
    find_each(&:register_storage)
  rescue ActiveRecord::StatementInvalid, NameError
    nil # migrations probably haven't run yet to create library table
  end

  def list_files(pattern, flags = 0)
    case storage_service
    when "filesystem"
      Dir.glob(pattern, flags, base: Shellwords.escape(path)).filter { |x| File.file?(File.join(path, x)) }
    else
      raise "Invalid storage service: #{storage_service}"
    end
  end

  def has_file?(path)
    storage.exists?(path)
  end

  def has_folder?(path)
    storage.exists?(path)
  end

  def file_last_modified(file)
    case storage_service
    when "filesystem"
      File.mtime(File.join(path, file))
    else
      raise "Invalid storage service: #{storage_service}"
    end
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
