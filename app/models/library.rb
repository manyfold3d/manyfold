class Library < ApplicationRecord
  has_many :models, dependent: :destroy
  validates :path, presence: true, uniqueness: true

  def name
    File.basename(path)
  end
end
