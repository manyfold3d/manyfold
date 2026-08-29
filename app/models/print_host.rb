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

  has_many :print_jobs, dependent: :destroy
  has_many :sliced_artifacts, dependent: :destroy
  has_many :resin_bottles, dependent: :nullify
  has_many :print_vats, dependent: :destroy

  validates :name, presence: true
  validates :endpoint, presence: true
  validates :protocol, presence: true, inclusion: {in: PROTOCOLS.keys}
  validate :endpoint_must_be_http_url
  validate :endpoint_must_be_private_lan
  validate :mainboard_id_format
  validates :fep_cycles, numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_nil: true
  validates :lcd_hours, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validates :resolution_w, :resolution_h, numericality: {greater_than: 0, only_integer: true}, allow_nil: true
  validates :build_x_mm, :build_y_mm, :build_z_mm, numericality: {greater_than: 0}, allow_nil: true
  validates :storage_bytes_used, :storage_bytes_total, numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_nil: true

  # SDCP control is always :3030. Bare http://IP (URI default :80) must not stick.
  before_validation :normalize_sdcp_endpoint_port

  def service
    PROTOCOLS.fetch(protocol).new(print_host: self)
  end

  def input_types
    PROTOCOLS.fetch(protocol)::INPUT_TYPES
  end

  # Prefer capability stamp when present; fall back to protocol defaults.
  def capability_formats
    formats = Array(native_formats).map(&:to_s).reject(&:blank?)
    formats.presence || input_types.map(&:to_s)
  end

  def resolution_label
    return if resolution_w.blank? || resolution_h.blank?

    "#{resolution_w}×#{resolution_h}"
  end

  # i18n-tasks-use t('print_hosts.protocols.sdcp')
  def protocol_label
    case protocol
    when Print::SdcpService::PROTOCOL
      I18n.t("print_hosts.protocols.sdcp")
    else
      protocol
    end
  end

  # Decorative / future-protocol families (Bambu/X1C) are visible but not send-capable (INIT-008).
  def unsupported_for_send?
    return true unless protocol == Print::SdcpService::PROTOCOL

    [brand, machine_model, name].compact.join(" ").match?(/bambu|x1[\s_-]?c/i)
  end

  def send_supported?
    !unsupported_for_send?
  end

  def endpoint_host_port
    uri = URI.parse(endpoint.to_s)
    port = uri.port
    host = uri.host
    return endpoint.to_s if host.blank?

    (port && ![80, 443].include?(port)) ? "#{host}:#{port}" : host.to_s
  rescue URI::InvalidURIError
    endpoint.to_s
  end

  def print_later(file:)
    SendFileToPrintHostJob.perform_later(self, file)
  end

  private

  def normalize_sdcp_endpoint_port
    return unless protocol == Print::SdcpService::PROTOCOL
    return if endpoint.blank?

    uri = URI.parse(endpoint.to_s)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?

    # URI#port returns scheme default (80/443) when omitted — wrong for SDCP.
    if uri.port.nil? || uri.port == uri.default_port
      uri.port = Print::SdcpService::DEFAULT_CONTROL_PORT
      self.endpoint = uri.to_s
    end
  rescue URI::InvalidURIError
    # covered by endpoint_must_be_http_url
  end

  def endpoint_must_be_http_url
    return if endpoint.blank?

    uri = URI.parse(endpoint)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:endpoint, :invalid)
    end
  rescue URI::InvalidURIError
    errors.add(:endpoint, :invalid)
  end

  def endpoint_must_be_private_lan
    return if endpoint.blank?
    return if errors[:endpoint].present?

    uri = URI.parse(endpoint)
    unless Print::EndpointAllowlist.allowed?(uri.host)
      errors.add(:endpoint, :not_private_lan)
    end
  rescue URI::InvalidURIError
    # covered by endpoint_must_be_http_url
  end

  def mainboard_id_format
    return if mainboard_id.blank?
    # SDCP MainboardID is a hex string (observed 16 chars; allow 8–32).
    unless /\A[0-9a-fA-F]{8,32}\z/.match?(mainboard_id)
      errors.add(:mainboard_id, :invalid)
    end
  end
end
