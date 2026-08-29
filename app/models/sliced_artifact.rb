# frozen_string_literal: true

# Already-sliced printable artifact (CTB/JXS/…) linked to a model and target printer.
# Produced by external slicer / INIT-009; manager never re-slices (INIT-008 ADR 0007).
class SlicedArtifact < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.sliced_artifact")

  belongs_to :model
  belongs_to :print_host
  belongs_to :model_file, optional: true
  has_many :print_jobs, dependent: :nullify

  validates :format, presence: true
  validates :estimated_layers, numericality: {greater_than: 0, only_integer: true}, allow_nil: true
  validates :estimated_duration_seconds, numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_nil: true
  validates :estimated_resin_ml, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
end
