class Model < ApplicationRecord
  belongs_to :library
  belongs_to :creator, optional: true
  has_many :parts, dependent: :destroy
  has_many :images, dependent: :destroy
  belongs_to :preview_part, class_name: "Part", optional: true
  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}
  has_many :links, as: :linkable, dependent: :destroy
  accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true

  default_scope { order(:name) }

  acts_as_taggable_on :tags

  def autogenerate_tags_from_path!
    tag_list.add(path.split(File::SEPARATOR)[1..-2].map { |y| y.split(/[\W_+-]/).filter { |x| x.length > 1 } }.flatten)
    save!
  end
end
