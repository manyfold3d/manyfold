class Model < ApplicationRecord
  extend Memoist

  belongs_to :library
  belongs_to :creator, optional: true
  has_many :model_files, dependent: :destroy
  belongs_to :preview_file, class_name: "ModelFile", optional: true
  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}
  has_many :links, as: :linkable, dependent: :destroy
  accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true

  attr_accessor :organize

  before_update :move_files

  default_scope { order(:name) }

  acts_as_taggable_on :tags

  def autogenerate_tags_from_path!
    tags = File.split(path).last.split(/[\W_+-]/).filter { |x| x.length > 1 }

    if SiteSettings.model_tags_filter_stop_words
      @filter ||= Stopwords::Snowball::Filter.new(SiteSettings.model_tags_stop_words_locale, SiteSettings.model_tags_custom_stop_words)
      tags = @filter.filter(tags)
    end

    unless tags.empty?
      tag_list.add(tags)
      save!
    end
  end

  def parents
    Pathname.new(path).parent.descend.map do |path|
      library.models.find_by_path(path.to_s)
    end.compact
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

  def formatted_path
    File.join("", tags.order(taggings_count: :desc).map(&:to_s).map(&:parameterize), name.parameterize) + "##{id}"
  end

  def contained_models
    library.models.where("path LIKE ?", Model.sanitize_sql_like(path) + "/%")
  end

  def contains_other_models?
    contained_models.exists?
  end

  private

  def create_folder_if_necessary(folder)
    return if Dir.exist?(folder)
    create_folder_if_necessary(File.dirname(folder))
    Dir.mkdir(folder)
  end

  def move_files
    if ActiveModel::Type::Boolean.new.cast(organize) && !contains_other_models?
      old_path = File.join(library.path, path)
      new_path = File.join(library.path, formatted_path)
      create_folder_if_necessary(File.dirname(new_path))
      File.rename(old_path, new_path)
      self.path = formatted_path
    end
  end
end
