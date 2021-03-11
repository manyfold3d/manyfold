class Library < ApplicationRecord
  has_many :models, dependent: :destroy
  validates :path, presence: true, uniqueness: true

  default_scope { order(:path) }

  def name
    File.basename(path)
  end
end
