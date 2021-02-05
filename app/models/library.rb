class Library < ApplicationRecord
  validates :path, presence: true
end
