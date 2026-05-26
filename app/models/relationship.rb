class Relationship < ApplicationRecord
  PREDICATES = [
    "adapted_from",
    "alternative_format_of",
    "supported_version_of"
  ]

  belongs_to :subject, polymorphic: true
  belongs_to :objekt, polymorphic: true

  validates :predicate, uniqueness: {scope: [:subject, :objekt]}, inclusion: {in: PREDICATES}
end
