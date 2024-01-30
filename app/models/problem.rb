class Problem < ApplicationRecord
  belongs_to :problematic, polymorphic: true

  validates :category, uniqueness: {scope: :problematic}, presence: true

  scope :visible, ->(settings) {
    enabled = settings.select { |cat, sev| sev.to_sym != :silent }
    where(category: enabled.keys)
  }

  CATEGORIES = [
    :missing,
    :empty,
    :destination_exists, # No longer used, but kept for compatibility
    :nesting,
    :inefficient,
    :duplicate
  ]
  enum :category, CATEGORIES

  SEVERITIES = [
    :silent,
    :info,
    :warning,
    :danger
  ]

  DEFAULT_SEVERITIES = {
    missing: :danger,
    empty: :info,
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
    ["category", "created_at", "id", "note", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["problematic"]
  end
end
