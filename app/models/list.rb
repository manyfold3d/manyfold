class List < ApplicationRecord
  include CaberObject
  include PublicIDable

  has_many :list_items, dependent: :destroy
  has_many :models, through: :list_items, source: :listable, source_type: "Model"

  accepts_nested_attributes_for :list_items, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, length: {maximum: 255}
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}
end
