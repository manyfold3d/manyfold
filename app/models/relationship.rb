class Relationship < ApplicationRecord
  PREDICATES = [
    "supported_version_of",
    "adapted_from"
  ]

  belongs_to :subject, polymorphic: true
  belongs_to :objekt, polymorphic: true

  validates :predicate, uniqueness: {scope: [:subject, :objekt]}, inclusion: {in: PREDICATES}
end
