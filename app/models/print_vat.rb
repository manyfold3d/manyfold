# frozen_string_literal: true

class PrintVat < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_vat")

  STATUSES = {
    ready: "ready",
    in_use: "in_use",
    maintenance: "maintenance",
    retired: "retired"
  }.freeze

  belongs_to :print_host
  belongs_to :resin_bottle, optional: true

  enum :status, STATUSES, default: :ready, validate: true

  validates :identity, presence: true, uniqueness: {scope: :print_host_id}
  validates :fep_cycles, numericality: {greater_than_or_equal_to: 0, only_integer: true}
end
