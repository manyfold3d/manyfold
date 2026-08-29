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

    # UDP discover may target limited broadcast in addition to private LAN hosts.
    DISCOVER_BROADCAST = "255.255.255.255"

    def allowed?(host)
      return false if host.blank?

      ip = IPAddr.new(Resolv.getaddress(host.to_s))
      ALLOWED_CIDRS.any? { |cidr| cidr.include?(ip) }
    rescue Resolv::ResolvError, IPAddr::InvalidAddressError
      false
    end

    # Discover targets: private LAN (incl. directed broadcast like 10.0.0.255) or limited broadcast.
    def allowed_discover_target?(host)
      return false if host.blank?
      return true if host.to_s.strip == DISCOVER_BROADCAST

      allowed?(host)
    end

    def filter_discover_targets(hosts)
      Array(hosts).map { |h| h.to_s.strip }.reject(&:blank?).select { |h| allowed_discover_target?(h) }.uniq
    end
  end
end
