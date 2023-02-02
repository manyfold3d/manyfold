class Model < ApplicationRecord
  extend Memoist

  belongs_to :library
  belongs_to :creator, optional: true
  has_many :model_files, dependent: :destroy
  belongs_to :preview_file, class_name: "ModelFile", optional: true
  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}
  validate :cannot_move_models_with_submodels, on: :update
  has_many :links, as: :linkable, dependent: :destroy
  has_many :problems, as: :problematic, dependent: :destroy
  accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true

  attr_accessor :organize

  before_update :move_files

  scope :recent, -> { order(created_at: :desc) }

  acts_as_taggable_on :tags, :collections

  def autogenerate_tags_from_path!
    tags = []

    # Auto-tag based on model directory name:
    if SiteSettings.model_tags_tag_model_directory_name
      tags = File.split(path).last.split(/[\W_+-]/).filter { |x| x.length > 1 }
    end

    # (optional) stopwords to remove from auto tagging
    if SiteSettings.model_tags_filter_stop_words
      @filter ||= Stopwords::Snowball::Filter.new(SiteSettings.model_tags_stop_words_locale, SiteSettings.model_tags_custom_stop_words)
      tags = @filter.filter(tags)
    end

    unless tags.empty?
      tag_list.add(tags)
      save!
    end
  end

  def autogenerate_creator_from_prefix_template!
    if SiteSettings.model_tags_tag_model_path_prefix
      filepaths = File.dirname(path).split("/")
      filepaths.shift
      templatechunks = SiteSettings.model_path_prefix_template.split("/")
      creatornew = ""
      collectionnew = ""
      tags = []
      while !templatechunks.empty? && !filepaths.empty? && !(templatechunks.length == 1 && templatechunks[0] == "tags") do
        if templatechunks[0] == "creator" then
          creatornew = filepaths.shift
          templatechunks.shift
        elsif templatechunks[0] == "collection" then
          collectionnew = filepaths.shift
          templatechunks.shift
        elsif templatechunks[-1] == "creator" then
          creatornew = filepaths.pop
          templatechunks.pop
        elsif templatechunks[-1] == "collection" then
          collectionnew = filepaths.pop
          templatechunks.pop
        else
          logger.error "Invalid model_path_prefix_template: #{SiteSettings.model_path_prefix_template} / #{templatechunks[0]}"
          templatechunks.shift
        end
      end
      if templatechunks.length == 1 && templatechunks[0] == "tags" then
        tags = filepaths
      end
      unless tags.empty?
        tag_list.add(tags)
      end
      unless creatornew.empty?
        creator = Creator.find_by(name: creatornew)
        unless creator
          creator = Creator.create(name: creatornew)
        end
        self.creator_id = creator.id
      end
      unless collectionnew.empty? && !self.collection_list
        collection_list.add(collectionnew)
      end
      save!
    end
  end

  def parents
    Pathname.new(path).parent.descend.map do |path|
      library.models.find_by(path: path.to_s)
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
    formatted_path_out = []
    SiteSettings.model_path_prefix_template.split("/").each { |p|
      case p
      when "tags"
        formatted_path_out.push(tags.order(taggings_count: :desc).map(&:to_s).map(&:parameterize))
      when "creator"
        formatted_path_out.push(creator ? creator.name : "unset-creator")
      when "collection"
        formatted_path_out.push(collections.count>0 ? collections.map{ |c| c.name } : "unset-collection")
      else
        formatted_path_out.push("bad-formatted-path-element")
      end
    }
    File.join("",formatted_path_out, name.parameterize) + (SiteSettings.model_path_suffix_model_id ? "##{id}" : "")
  end

  def contained_models
    Library.find(library_id_was).models.where("path LIKE ?", Model.sanitize_sql_like(path) + "/%")
  end

  def contains_other_models?
    contained_models.exists?
  end

  private

  def cannot_move_models_with_submodels
    if (library_id_changed? || ActiveModel::Type::Boolean.new.cast(organize)) && contains_other_models?
      errors.add(library_id_changed? ? :library : :organize, "can't move models containing other models")
    end
  end

  def create_folder_if_necessary(folder)
    return if Dir.exist?(folder)
    create_folder_if_necessary(File.dirname(folder))
    Dir.mkdir(folder)
  end

  def move_files
    if (library_id_changed? || ActiveModel::Type::Boolean.new.cast(organize)) && !contains_other_models?
      old_path = File.join(Library.find(library_id_was).path, path)
      new_path = File.join(library.path, formatted_path)
      create_folder_if_necessary(File.dirname(new_path))
      if !File.exists?(new_path)
        File.rename(old_path, new_path)
        self.path = formatted_path
      else
        self.problems.create(category: :destination_exists)
      end
    end
  end
end
