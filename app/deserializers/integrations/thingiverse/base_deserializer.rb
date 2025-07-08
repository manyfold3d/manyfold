class Integrations::Thingiverse::BaseDeserializer
  attr_reader :uri

  def initialize(uri:, api_key: ENV.fetch("THINGIVERSE_API_KEY"))
    @uri = canonicalize(uri)
    @api_key = api_key
  end

  def valid?(for_class: nil)
    @uri.present? && (for_class ? for_class == target_class : true)
  end

  def deserialize
    raise NotImplementedError
  end

  private

  def target_class
    raise NotImplementedError
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

  def valid_path?(path)
    true
  end
end
