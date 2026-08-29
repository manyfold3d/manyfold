# frozen_string_literal: true

# Durable queue / history record for Print Studio (INIT-008/SPEC-002).
# History UI reads terminal jobs (succeeded/failed/cancelled) with outcome fields.
class PrintJob < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_job")

  STATES = {
    queued: "queued",
    waiting_plate: "waiting_plate",
    printing: "printing",
    paused: "paused",
    succeeded: "succeeded",
    failed: "failed",
    cancelled: "cancelled"
  }.freeze

  TERMINAL_STATES = %w[succeeded failed cancelled].freeze
  ACTIVE_STATES = %w[queued waiting_plate printing paused].freeze

  belongs_to :print_host
  belongs_to :model, optional: true
  belongs_to :model_file, optional: true
  belongs_to :user, optional: true
  belongs_to :sliced_artifact, optional: true

  enum :state, STATES, default: :queued, validate: true

  validates :print_host, presence: true
  validates :estimated_duration_seconds, :actual_duration_seconds,
    numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_nil: true
  validates :layer_count, :current_layer,
    numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_nil: true
  validates :estimated_resin_ml, :actual_resin_ml,
    numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validate :only_one_printing_per_host, if: -> { printing? && print_host_id.present? }

  scope :history, -> { where(state: TERMINAL_STATES).order(finished_at: :desc, updated_at: :desc) }
  scope :active, -> { where(state: ACTIVE_STATES) }
  scope :for_host, ->(host) { where(print_host: host) }

  def terminal?
    TERMINAL_STATES.include?(state)
  end

  def history_outcome
    outcome.presence || state
  end

  private

  def only_one_printing_per_host
    conflict = self.class.where(print_host_id: print_host_id, state: :printing)
    conflict = conflict.where.not(id: id) if persisted?
    return unless conflict.exists?

    errors.add(:state, :one_printing_per_host)
  end
end
