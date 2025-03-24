class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  FEDIVERSE_USERNAMES = {
    user: :public_id,
    creator: :slug,
    collection: :public_id,
    model: :public_id
  }

  def self.ransackable_symbols
    (ransackable_attributes + ransackable_associations + ransackable_scopes).map(&:to_sym)
  end

  # Default find_param implementation
  # just the same as standard find()
  def self.find_param(param)
    find(param)
  end
end
