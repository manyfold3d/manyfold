class Problem < ApplicationRecord
  belongs_to :problematic, polymorphic: true

  validates :category, uniqueness: {scope: :problematic}, presence: true

  enum :category, [
    :missing,
    :empty,
    :destination_exists, # No longer used, but kept for compatibility
    :nesting,
    :inefficient
  ]

  def self.create_or_clear(problematic, cat, present, options = {})
    if present
      problematic.problems.create(options.merge(category: cat))
    else
      problematic.problems.where(category: cat).destroy_all
    end
    present
  end
end
