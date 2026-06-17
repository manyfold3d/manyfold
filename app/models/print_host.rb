class PrintHost < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_host")

  PROTOCOLS = Print.constants.map { [const_get("Print::#{it}::PROTOCOL"), const_get("Print::#{it}")] }.to_h.freeze

  class NotReady < RuntimeError
  end

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS.keys}

  def service
    PROTOCOLS[protocol].new(print_host: self)
  end

  def input_types
    PROTOCOLS[protocol]::INPUT_TYPES
  end

  def print_later(file:)
    SendFileToPrintHostJob.perform_later(print_host: self, file: file)
  end
end
