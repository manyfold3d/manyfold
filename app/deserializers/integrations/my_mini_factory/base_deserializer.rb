module Integrations::MyMiniFactory
  class BaseDeserializer < Integrations::BaseDeserializer
    USERNAME_PATTERN = /[[:alnum:]\-_ ]+/

    private

    def api_configured?
      SiteSettings.myminifactory_api_key.present?
    end

    def fetch(api_url)
      connection = Faraday.new do |builder|
        builder.response :json
        builder.response :raise_error
      end
      connection.get "https://www.myminifactory.com/api/v2/#{api_url}", {key: SiteSettings.myminifactory_api_key}, {Accept: "application/json"}
    end

    def canonicalize(uri)
      u = URI.parse(uri)
      u.host = "www.myminifactory.com" if u.host == "myminifactory.com"
      return if u.host != "www.myminifactory.com"
      return unless valid_path?(u.path)
      # Force https
      u.scheme = "https"
      # Remove query and fragment
      u.query = u.fragment = nil
      u.to_s
    rescue URI::InvalidURIError
    end

    def creator_attributes(data)
      return {} if data.nil? || (data["profile_url"].nil? && data["username"].nil?)
      attempt_creator_match(Integrations::MyMiniFactory::CreatorDeserializer.parse(data))
    end
  end
end
