class Library < ApplicationRecord
  has_many :models, dependent: :destroy
  has_many :model_files, through: :models
  validates :path, presence: true, uniqueness: true, existing_path: true

  default_scope { order(:path) }

  def name
    File.basename(path)
  end
end
