class Part < ApplicationRecord
  belongs_to :model
  validates :filename, presence: true
end
