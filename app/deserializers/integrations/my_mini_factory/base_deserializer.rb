class Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :uri

  def initialize(uri:, api_key: ENV.fetch("MYMINIFACTORY_API_KEY"))
    @uri = canonicalize(uri)
    @api_key = api_key
  end

  def valid?
    @uri.present?
  end

  def deserialize
    raise NotImplementedError
  end

  private

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

  def valid_path?(path)
    true
  end
end
