class Part < ApplicationRecord
  belongs_to :model
  validates :filename, presence: true, uniqueness: {scope: :model}
end
