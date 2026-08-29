# frozen_string_literal: true

require "cgi"
require "net/http"
require "uri"

module Print
  # Cluster-internal go2rtc HTTP client. Never expose go2rtc API on a public VIP —
  # Manyfold authz is the front door (INIT-007/SPEC-004 + SPEC-006).
  # Fail-fast UI poll budgets: INIT-009/SPEC-002 (ADR D-1).
  class Go2rtcClient
    class Error < StandardError; end

    # Binding caps from INIT-009 ADR D-1 (REQ-002).
    GO2RTC_OPEN_TIMEOUT = 2
    GO2RTC_READ_TIMEOUT = 3
    MIN_JPEG_BYTES = 100

    def self.base_url
      ENV.fetch("GO2RTC_URL", "http://go2rtc.manyfold.svc.cluster.local:1984").to_s.chomp("/")
    end

    def self.frame_jpeg(stream:)
      uri = URI.parse("#{base_url}/api/frame.jpeg?src=#{CGI.escape(stream.to_s)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = GO2RTC_OPEN_TIMEOUT
      http.read_timeout = GO2RTC_READ_TIMEOUT
      response = http.get(uri.request_uri)
      body = response.body
      unless response.is_a?(Net::HTTPSuccess) && body.present? && body.bytesize > MIN_JPEG_BYTES
        raise Error, "go2rtc frame empty or HTTP #{response.code}"
      end
      body
    rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Timeout::Error => e
      raise Error, e.message
    end
  end
end
