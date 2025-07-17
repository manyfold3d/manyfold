class Integrations::Thingiverse::CollectionDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :collection_id

  def deserialize
    return {} unless valid?
    r = fetch "collections/#{CGI.escapeURIComponent(@collection_id)}"
    {
      name: r.body["name"],
      notes: r.body["description"]
    }.merge(creator_attributes(r.body["creator"]))
  end

  def capabilities
    {
      class: Collection,
      name: true,
      notes: true,
      creator: true
    }
  end

  private

  def valid_path?(path)
    match = /\A\/(#{USERNAME_PATTERN})\/collections\/([[:digit:]-]+)\/things\Z/o.match(CGI.unescape(path))
    if match.present?
      @username = match[1]
      @collection_id = match[2]
    end
    match.present?
  end
end
