class Model < ApplicationRecord
  extend Memoist
  include PathBuilder
  include PathParser
  include Followable

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

  before_validation :normalize_license
  # In Rails 7.1 we will be able to do this instead:
  # normalizes :license, with: -> license { license.blank? ? nil : license }

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
    ["caption", "created_at", "id", "library_id", "name", "notes", "path", "slug", "updated_at", "license_cont", "license"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["base_tags", "collection", "creator", "library", "links", "model_files", "preview_file", "problems", "tag_taggings", "taggings", "tags"]
  end

  def problems_including_files
    Problem.where(problematic: model_files + [self])
  end

  def new?
    tags.where(name: SiteSettings.model_tags_auto_tag_new).any?
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

  private

  def normalize_license
    self.license = nil if license.blank?
  end

  def strip_separators_from_path
    self.path = path&.trim_path_separators
  end

  def previous_library
    library_id_changed? ? Library.find(library_id_was) : library
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

  def slugify_name
    self.slug = name.parameterize
  end
end
