class Library < ApplicationRecord
  has_many :models
  validates :path, presence: true, uniqueness: true
end
