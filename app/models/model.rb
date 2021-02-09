class Model < ApplicationRecord
  belongs_to :library
  has_many :parts, dependent: :destroy
  validates :name, presence: true
  validates :path, presence: true, uniqueness: {scope: :library}
end
