class Integrations::Thangs::BaseDeserializer < Integrations::BaseDeserializer
  PATH_COMPONENTS = {
    username: /(?<username>[[:alnum:]\- ]+)/,
    model_slug: /(?<model_slug>[[:alnum:]\- ]+)/,
    model_id: /(?<model_id>[[:digit:]]+)/
  }
  USERNAME_PATTERN = /[[:alnum:]_\-]+/

  private

  def api_configured?
    false
  end

  def fetch(api_url)
    connection = Faraday.new do |builder|
      builder.response :json
      builder.response :raise_error
    end
    connection.get("https://thangs.com/api/#{api_url}", {},
      {
        Accept: "application/json"
      })
  end

  def canonicalize(uri)
    u = URI.parse(uri)
    return if u.host != "thangs.com"
    return unless valid_path?(u.path)
    # Force https
    u.scheme = "https"
    # Remove query and fragment
    u.query = u.fragment = nil
    u.to_s
  rescue URI::InvalidURIError
  end
end
