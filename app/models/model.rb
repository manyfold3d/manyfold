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

  attr_accessor :organize

  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}

  

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

  private

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
    library_id_changed? || path_changed?
  end

  end
end
