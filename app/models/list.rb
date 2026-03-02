class List < ApplicationRecord
  include CaberObject
  include PublicIDable

  has_many :list_items, dependent: :destroy
  has_many :models, through: :list_items, source: :listable, source_type: "Model"

  validates :name, presence: true, length: {maximum: 255}
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}
end
