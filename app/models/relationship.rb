class Relationship < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.relationship")

  MODEL_TO_MODEL_PREDICATES = [
    "adapted_from" # i18n-tasks-use t("activerecord.models.relationships.predicates.adapted_from")
  ]

  FILE_TO_FILE_PREDICATES = [
    "alternative_format_of", # i18n-tasks-use t("activerecord.models.relationships.predicates.alternative_format_of")
    "supported_version_of" # i18n-tasks-use t("activerecord.models.relationships.predicates.supported_version_of")
  ]

  ALL_PREDICATES = MODEL_TO_MODEL_PREDICATES + FILE_TO_FILE_PREDICATES

  belongs_to :subject, polymorphic: true
  belongs_to :objekt, polymorphic: true

  validates :predicate, uniqueness: {scope: [:subject, :objekt]}, inclusion: {in: ALL_PREDICATES}
end
