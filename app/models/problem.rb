class Problem < ApplicationRecord
  belongs_to :problematic, polymorphic: true

  enum :category, [:missing]
end
