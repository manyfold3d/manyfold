require "shrine/storage/memory"

class Library < ApplicationRecord
  has_many :models, dependent: :destroy
  has_many :model_files, through: :models
  has_many :problems, as: :problematic, dependent: :destroy
  serialize :tag_regex, type: Array
  after_initialize :init
  before_validation :ensure_path_case_is_correct
  after_save :register_storage

  validates :path, presence: true, uniqueness: true, existing_path: true

  default_scope { order(:path) }

  def name
    self[:name] || (path ? File.basename(path) : "")
  end

  def init
    self.name = nil if name == ""
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
    return Shrine::Storage::Memory.new if Rails.env.test?
    Shrine::Storage::FileSystem.new(path)
  end

  def register_storage
    Shrine.storages[storage_key] = storage
  end

  private

  def ensure_path_case_is_correct
    # On case-preserving-and-insensitive filesystems (i.e. macOS)
    # if you get the case wrong, the library can be created, but then
    # models will get the wrong paths. This method makes sure that the
    # case is stored in the canonical form that the OS will give us back
    # in globs
    if path
      normalised = Dir.glob(path).first
      self.path = normalised if normalised
    end
  end
end
