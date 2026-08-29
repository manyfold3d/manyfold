# frozen_string_literal: true

# Thin stub for Model Print Log sidebar curation notes (INIT-008/SPEC-002).
class PrintCurationNote < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_curation_note")

  belongs_to :model
  belongs_to :user, optional: true

  validates :body, presence: true
end
