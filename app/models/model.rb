class Model < ApplicationRecord
  extend Memoist
  include PathBuilder
  include PathParser

  scope :recent, -> { order(created_at: :desc) }

  belongs_to :library
  belongs_to :creator, optional: true
  belongs_to :collection, optional: true
  belongs_to :preview_file, class_name: "ModelFile", optional: true
  has_many :model_files, dependent: :destroy
  has_many :links, as: :linkable, dependent: :destroy
  has_many :problems, as: :problematic, dependent: :destroy
  acts_as_taggable_on :tags

  accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true

  before_validation :strip_separators_from_path, if: :path_changed?
  before_validation :slugify_name, if: :name_changed?

  attr_reader :organize
  def organize=(value)
    @organize = ActiveRecord::Type::Boolean.new.cast(value)
  end

  before_validation :autoupdate_path, if: :organize

  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}
  validate :check_for_submodels, on: :update, if: :need_to_move_files?
  validate :destination_is_vacant, on: :update, if: :need_to_move_files?
  validates :license, spdx: true, allow_nil: true

  before_update :move_files, if: :need_to_move_files?

  def parents
    Pathname.new(path).parent.descend.filter_map do |path|
      library.models.find_by(path: path.to_s)
    end
  end
  memoize :parents

  def merge_into!(target)
    return unless target

    # Work out path to this model from the target
    relative_path = Pathname.new(path).relative_path_from(Pathname.new(target.path))
    # Move files
    model_files.each do |f|
      f.update(
        filename: File.join(relative_path, f.filename),
        model: target
      )
    end
    reload
    destroy
  end

  def delete_from_disk_and_destroy
    # Trigger deletion for each file separately, to make sure cleanup happens
    model_files.each { |f| f.delete_from_disk_and_destroy }
    # Delete directory corresponding to model
    FileUtils.remove_dir(absolute_path) if File.exist?(absolute_path)
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

  def absolute_path
    File.join(library.path, path)
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "id", "name", "notes", "path", "slug", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["base_tags", "collection", "creator", "library", "links", "model_files", "preview_file", "problems", "tag_taggings", "taggings", "tags"]
  end

  private

  def strip_separators_from_path
    self.path = path&.trim_path_separators
  end

  def previous_library
    library_id_changed? ? Library.find(library_id_was) : library
  end

  def previous_path
    path_changed? ? path_was : path
  end

  def previous_absolute_path
    File.join(previous_library.path, previous_path)
  end

  def need_to_move_files?
    (library_id_changed? || path_changed?) && absolute_path != previous_absolute_path
  end

  def autoupdate_path
    self.path = formatted_path
  end

  def check_for_submodels
    if contains_other_models?
      errors.add(library_id_changed? ? :library : :path, "can't be changed, model contains other models")
    end
  end

  def destination_is_vacant
    if Dir.exist?(absolute_path)
      errors.add(:path, "already exists")
    end
  end

  def move_files
    # Sometimes, if we're trimming separators or normalising paths, we get here
    # but the path hasn't actually changed on disk. In that case, we're done.
    return if absolute_path == previous_absolute_path
    # Move the folder
    FileUtils.mkdir_p(File.dirname(absolute_path))
    File.rename(previous_absolute_path, absolute_path)
  end

  def slugify_name
    self.slug = name.parameterize
  end
end
