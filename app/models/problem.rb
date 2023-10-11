class Problem < ApplicationRecord
  belongs_to :problematic, polymorphic: true

  validates :category, uniqueness: {scope: :problematic}, presence: true

  enum :category, [
    :missing,
    :empty,
    :destination_exists, # No longer used, but kept for compatibility
    :nesting,
    :inefficient,
    :duplicate
  ]

  SEVERITIES = [
    :silent,
    :info,
    :warning,
    :danger
  ]

  DEFAULT_SEVERITIES = {
    missing: :danger,
    empty: :info,
    destination_exists: :silent,
    nesting: :warning,
    inefficient: :info,
    duplicate: :warning
  }

  def self.create_or_clear(problematic, cat, present, options = {})
    if present
      problematic.problems.create(options.merge(category: cat))
    else
      problematic.problems.where(category: cat).destroy_all
    end
    present
  end

  def self.ransackable_attributes(auth_object = nil)
    ["category", "created_at", "id", "note", "problematic_id", "problematic_type", "updated_at"]
  end
end
