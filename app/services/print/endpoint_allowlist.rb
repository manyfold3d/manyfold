# frozen_string_literal: true

require "ipaddr"
require "resolv"

module Print
  # Reject PrintHost endpoints that are not RFC1918 / link-local / loopback.
  # Prevents SSRF into cluster DNS / cloud metadata (INIT-007/SPEC-006).
  module EndpointAllowlist
    module_function

    ALLOWED_CIDRS = [
      IPAddr.new("10.0.0.0/8"),
      IPAddr.new("172.16.0.0/12"),
      IPAddr.new("192.168.0.0/16"),
      IPAddr.new("127.0.0.0/8"),
      IPAddr.new("::1")
    ].freeze

    def allowed?(host)
      return false if host.blank?

      ip = IPAddr.new(Resolv.getaddress(host.to_s))
      ALLOWED_CIDRS.any? { |cidr| cidr.include?(ip) }
    rescue Resolv::ResolvError, IPAddr::InvalidAddressError
      false
    end
  end
end
