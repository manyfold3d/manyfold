class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.ransackable_symbols
    (ransackable_attributes + ransackable_associations + ransackable_scopes).map(&:to_sym)
  end
end
