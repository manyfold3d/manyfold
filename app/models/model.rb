class Model < ApplicationRecord
  belongs_to :library
  has_many :parts, dependent: :destroy
  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}

  acts_as_taggable_on :tags

  def autogenerate_tags_from_path!
    tag_list.add(path.split(File::SEPARATOR)[1..-2].map{|y| y.split(/[\W_]/).filter{ |x| x.length > 1 }}.flatten)
    save!
  end

end
