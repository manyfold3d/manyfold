class Integrations::Cults3d::BaseDeserializer
  attr_reader :uri

  # USERNAME_PATTERN = /[[:alnum:]_\-]+/

  def initialize(uri:)
    @uri = canonicalize(uri)
  end

  def valid?(for_class: nil)
    SiteSettings.cults3d_api_key.present? && SiteSettings.cults3d_api_username.present? && @uri.present? && (for_class ? for_class == target_class : true)
  end

  def deserialize
    raise NotImplementedError
  end

  private

  # def fetch(api_url)
  #   connection = Faraday.new do |builder|
  #     builder.response :json
  #   end
  #   connection.get("https://api.thingiverse.com/#{api_url}", {},
  #     {
  #       Authorization: "Bearer #{SiteSettings.thingiverse_api_key}",
  #       Accept: "application/json"
  #     })
  # end

  def target_class
    raise NotImplementedError
  end

  def canonicalize(uri)
    u = URI.parse(uri)
    return if u.host != "cults3d.com"
    return unless valid_path?(u.path)
    # Force https
    u.scheme = "https"
    # Remove query and fragment
    u.query = u.fragment = nil
    u.to_s
  rescue URI::InvalidURIError
  end

  def valid_path?(path)
    true
  end
end
