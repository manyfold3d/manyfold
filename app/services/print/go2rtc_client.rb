# frozen_string_literal: true

require "cgi"
require "net/http"
require "uri"

module Print
  # Cluster-internal go2rtc HTTP client. Never expose go2rtc API on a public VIP —
  # Manyfold authz is the front door (INIT-007/SPEC-004 + SPEC-006).
  class Go2rtcClient
    class Error < StandardError; end

    def self.base_url
      ENV.fetch("GO2RTC_URL", "http://go2rtc.manyfold.svc.cluster.local:1984").to_s.chomp("/")
    end

    def self.frame_jpeg(stream:)
      uri = URI.parse("#{base_url}/api/frame.jpeg?src=#{CGI.escape(stream.to_s)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      http.read_timeout = 25
      response = http.get(uri.request_uri)
      unless response.is_a?(Net::HTTPSuccess) && response.body.present? && response.body.bytesize > 100
        raise Error, "go2rtc frame empty or HTTP #{response.code}"
      end
      response.body
    rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Timeout::Error => e
      raise Error, e.message
    end
  end
end
