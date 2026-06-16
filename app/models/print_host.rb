class PrintHost < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_host")

  PROTOCOLS = Print.constants.map { [const_get("Print::#{it}::PROTOCOL"), const_get("Print::#{it}")] }.to_h.freeze

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS.keys}
end
