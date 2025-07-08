class Integrations::Thingiverse::CollectionDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :collection_id

  def deserialize
    return {} unless valid?
    # Fetch from MMF API
    connection = Faraday.new do |builder|
      builder.response :json
    end
    r = connection.get("https://api.thingiverse.com/collections/#{CGI.escapeURIComponent(@collection_id)}",
      {},
      {
        Authorization: "Bearer #{@api_key}",
        Accept: "application/json"
      })
    {
      name: r.body["name"],
      notes: r.body["description"]
    }
  end

  private

  def target_class
    Collection
  end

  def valid_path?(path)
    match = /\A\/(#{USERNAME_PATTERN})\/collections\/([[:digit:]-]+)\/things\Z/o.match(CGI.unescape(path))
    if match.present?
      @username = match[1]
      @collection_id = match[2]
    end
    match.present?
  end
end
