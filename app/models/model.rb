class Model < ApplicationRecord
  belongs_to :library
  validates :name, presence: true
  validates :path, presence: true
end
