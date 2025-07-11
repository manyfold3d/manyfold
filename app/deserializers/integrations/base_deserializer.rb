class Integrations::BaseDeserializer
  attr_reader :uri

  def initialize(uri:)
    @uri = canonicalize(uri)
  end

  def valid?(for_class: nil)
    api_configured? && @uri.present? && (for_class ? for_class == target_class : true)
  end

  def deserialize
    raise NotImplementedError
  end

  private

  def api_configured?
    raise NotImplementedError
  end

  def target_class
    raise NotImplementedError
  end

  def canonicalize(uri)
    raise NotImplementedError
  end

  def valid_path?(path)
    true
  end

  def filename_from_url(url)
    return if url.blank?
    CGI.unescape(url).split("/")&.last
  end
end
