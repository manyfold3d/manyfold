class PrintHost < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_host")

  PROTOCOLS = Print.constants.map { const_get("Print::#{it}::PROTOCOL") }.freeze

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS}
end
