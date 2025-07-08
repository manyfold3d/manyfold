class Integrations::MyMiniFactory::CollectionDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :collection_slug

  def deserialize
    return {} unless valid?
    # Fetch from MMF API
    connection = Faraday.new do |builder|
      builder.response :json
    end
    r = connection.get("https://www.myminifactory.com/api/v2/users/#{CGI.escapeURIComponent(@username)}/collections/#{CGI.escapeURIComponent(@collection_slug)}",
      {key: @api_key},
      {Accept: "application/json"})
    {
      name: r.body["name"]
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
