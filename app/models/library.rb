class Library < ApplicationRecord
  has_many :models, dependent: :destroy
  has_many :model_files, through: :models
  has_many :problems, as: :problematic, dependent: :destroy
  serialize :tag_regex, Array
  after_initialize :init

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
end
