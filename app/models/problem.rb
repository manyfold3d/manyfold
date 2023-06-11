class Problem < ApplicationRecord
  belongs_to :problematic, polymorphic: true

  validates :category, uniqueness: {scope: :problematic}, presence: true

  enum :category, [
    :missing,
    :empty,
    :destination_exists # No longer used, but kept for compatibility
  ]
end
