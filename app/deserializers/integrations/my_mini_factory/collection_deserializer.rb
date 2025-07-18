class Integrations::MyMiniFactory::CollectionDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :collection_slug

  def deserialize
    return {} unless valid?
    r = fetch "users/#{CGI.escapeURIComponent(@username)}/collections/#{CGI.escapeURIComponent(@collection_slug)}"
    {
      name: r.body["name"],
      models: r.body.dig("objects", "items")&.pluck("url")
    }.merge(creator_attributes(r.body["owner"]))
  end

  def capabilities
    {
      class: Collection,
      name: true,
      notes: false,
      creator: true,
      models: true
    }
  end

  private

  def valid_path?(path)
    match = /\A\/users\/(#{USERNAME_PATTERN})\/collection\/([[:alnum:]-]+)\Z/o.match(CGI.unescape(path))
    if match.present?
      @username = match[1]
      @collection_slug = match[2]
    end
    match.present?
  end
end
