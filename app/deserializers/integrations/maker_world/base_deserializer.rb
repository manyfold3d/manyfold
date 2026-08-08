module Integrations::MakerWorld
  class BaseDeserializer < Integrations::BaseDeserializer
    MAKERWORLD_API_BASE = "https://api.bambulab.com/v1/design-service"
    MAKERWORLD_DOWNLOAD_BASE = "https://api.bambulab.com/v1/iot-service/api/user/profile"
    MAKERWORLD_HOST = "makerworld.com"
    MODEL_ID_PATTERN = %r{/models/(?<model_id>[[:digit:]]+)}
    PROFILE_ID_PATTERN = /#profileId[-=](?<profile_id>[[:digit:]]+)/

    private

    def api_configured?
      true
    end

    def download_configured?
      SiteSettings.makerworld_bambu_token.present?
    end

    def fetch(api_path)
      get_json("#{MAKERWORLD_API_BASE}/#{api_path}", request_headers)
    end

    def fetch_download(profile_id:, model_id:)
      get_json(
        "#{MAKERWORLD_DOWNLOAD_BASE}/#{CGI.escapeURIComponent(profile_id.to_s)}?model_id=#{CGI.escapeURIComponent(model_id.to_s)}",
        request_headers.merge("Authorization" => "Bearer #{SiteSettings.makerworld_bambu_token}")
      )
    end

    def get_json(url, headers)
      connection.get(url, {}, headers)
    end

    def connection
      Faraday.new do |builder|
        builder.response :json
        builder.response :raise_error
      end
    end

    def request_headers
      {
        "Accept" => "application/json,*/*",
        "Accept-Language" => "en-US,en;q=0.9",
        "Referer" => "https://makerworld.com/"
      }
    end

    def canonicalize(uri)
      candidate = uri.to_s.strip
      candidate = "https://#{candidate}" unless candidate.include?("://")
      u = URI.parse(candidate)
      return unless u.host == MAKERWORLD_HOST || u.host&.end_with?(".#{MAKERWORLD_HOST}")
      return unless valid_path?(u.path, u.fragment)

      u.host = MAKERWORLD_HOST
      u.scheme = "https"
      u.path = "/models/#{@model_id}"
      u.query = nil
      u.fragment = @profile_id ? "profileId-#{@profile_id}" : nil
      u.to_s
    rescue URI::InvalidURIError
    end

    def valid_path?(path, fragment = nil)
      match = MODEL_ID_PATTERN.match(path)
      return false unless match

      @model_id = match[:model_id]
      profile_match = PROFILE_ID_PATTERN.match("##{fragment}")
      @profile_id = profile_match[:profile_id] if profile_match
      true
    end

    def selected_profile_id(design)
      if @profile_id.present?
        selected = Array.wrap(design["instances"]).find { |instance| instance["id"].to_s == @profile_id.to_s }
        return selected["profileId"] || selected["profile_id"] if selected

        return @profile_id
      end

      Array.wrap(design["instances"]).filter_map { |instance| instance["profileId"] || instance["profile_id"] }.first
    end
  end
end
