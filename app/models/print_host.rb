# frozen_string_literal: true

class PrintHost < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.print_host")

  class NotReady < RuntimeError
  end

  # Phase 1: SDCP only for UniFormation GK3. Other upstream protocols (octoprint,
  # moonraker, …) stay out of this map until a later initiative ports them.
  PROTOCOLS = {
    Print::SdcpService::PROTOCOL => Print::SdcpService
  }.freeze

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS.keys}
  validate :endpoint_must_be_http_url
  validate :mainboard_id_format

  def service
    PROTOCOLS.fetch(protocol).new(print_host: self)
  end

  def input_types
    PROTOCOLS.fetch(protocol)::INPUT_TYPES
  end

  def print_later(file:)
    SendFileToPrintHostJob.perform_later(self, file)
  end

  private

  def endpoint_must_be_http_url
    return if endpoint.blank?

    uri = URI.parse(endpoint)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:endpoint, :invalid)
    end
  rescue URI::InvalidURIError
    errors.add(:endpoint, :invalid)
  end

  def mainboard_id_format
    return if mainboard_id.blank?
    # SDCP MainboardID is a hex string (observed 16 chars; allow 8–32).
    unless /\A[0-9a-fA-F]{8,32}\z/.match?(mainboard_id)
      errors.add(:mainboard_id, :invalid)
    end
  end
end
