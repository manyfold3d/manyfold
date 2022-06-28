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
    [library.models.find_by_path(File.join(File.split(path)[0..-2]))].compact
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
end
