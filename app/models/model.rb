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
    @filter ||= Stopwords::Snowball::Filter.new "en"
    tags = @filter.filter(File.split(path).last.split(/[\W_+-]/).filter { |x| x.length > 1 })
    unless tags.empty?
      tag_list.add(tags)
      save!
    end
  end

  def parent
    library.models.find_by_path File.join(File.split(path)[0..-2])
  end
  memoize :parent

  def merge_into_parent!
    return unless parent

    dirname = ::File.split(path)[-1]
    model_files.each do |f|
      f.update(
        filename: File.join(dirname, f.filename),
        model: parent
      )
    end
    reload
    destroy
  end
end
