class Integrations::Thingiverse::BaseDeserializer < Integrations::BaseDeserializer
  USERNAME_PATTERN = /[[:alnum:]_\-]+/

  private

  def api_configured?
    SiteSettings.thingiverse_api_key.present?
  end

  def fetch(api_url)
    connection = Faraday.new do |builder|
      builder.response :json
    end
    connection.get("https://api.thingiverse.com/#{api_url}", {},
      {
        Authorization: "Bearer #{SiteSettings.thingiverse_api_key}",
        Accept: "application/json"
      })
  end

  def canonicalize(uri)
    u = URI.parse(uri)
    u.host = "www.thingiverse.com" if u.host == "thingiverse.com"
    return if u.host != "www.thingiverse.com"
    return unless valid_path?(u.path)
    # Force https
    u.scheme = "https"
    # Remove query and fragment
    u.query = u.fragment = nil
    u.to_s
  rescue URI::InvalidURIError
  end

  def creator_attributes(data)
    return {} if data.nil? || data["public_url"].nil?
    attempt_creator_match(Integrations::Thingiverse::CreatorDeserializer.parse(data))
  end
end
