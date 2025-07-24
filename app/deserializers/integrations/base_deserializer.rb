class Integrations::BaseDeserializer
  attr_reader :uri

  def initialize(uri:)
    @uri = canonicalize(uri)
  end

  def valid?(for_class: nil)
    api_configured? && @uri.present? && (for_class ? for_class == capabilities[:class] : true)
  end

  def deserialize
    raise NotImplementedError
  end

  def capabilities
    raise NotImplementedError
  end

  private

  def api_configured?
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

  def attempt_creator_match(attributes)
    c = Creator.linked_to(attributes.dig(:links_attributes, 0, :url)).first ||
      Creator.where(slug: attributes[:slug]).first || # rubocop:disable Pundit/UsePolicyScope
      Creator.where(name_lower: attributes[:name]&.downcase).first # rubocop:disable Pundit/UsePolicyScope
    c ? {creator: c} : {creator_attributes: attributes}
  end
end
