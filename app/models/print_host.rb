class PrintHost < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_host")

  PROTOCOLS = [
    "moonraker"
  ].freeze

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS}
end
