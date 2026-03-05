class List < ApplicationRecord
  include CaberObject
  include PublicIDable

  SUPPORTED_ITEM_TYPES = %w[Model]

  has_many :list_items, dependent: :destroy
  has_many :models, through: :list_items, source: :listable, source_type: "Model"

  accepts_nested_attributes_for :list_items, allow_destroy: true, reject_if: :reject_list_items_attributes

  validates :name, presence: true, length: {maximum: 255}
  validates :public_id, multimodel_uniqueness: {punctuation_sensitive: false, case_sensitive: false, check: FederailsCommon::FEDIVERSE_USERNAMES}

  def reject_list_items_attributes(item)
    # Reject blank
    return true if item.all? { |key, value| key == "_destroy" || value.blank? }
    # Reject anything that's not a supported type
    return true unless item["listable_type"].in?(SUPPORTED_ITEM_TYPES)
    # Well, alrighty then
    false
  end
end
