class List < ApplicationRecord
  has_many :list_items, dependent: :destroy
  has_many :models, through: :list_items, source: :listable, source_type: "Model"

  validates :name, presence: true, length: {maximum: 255}
end
