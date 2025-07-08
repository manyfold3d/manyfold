class Integrations::Thingiverse::CreatorDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :username

  def deserialize
    return {} unless valid?
    # Fetch from Thingiverse API
    connection = Faraday.new do |builder|
      builder.response :json
    end
    r = connection.get("https://api.thingiverse.com/users/#{CGI.escapeURIComponent(@username)}",
      {},
      {
        Authorization: "Bearer #{@api_key}",
        Accept: "application/json"
      })
    {
      name: r.body["name"],
      notes: ReverseMarkdown.convert(r.body["bio"])
    }
  end

  private

  def target_class
    Creator
  end

  def valid_path?(path)
    match = /\A\/(#{USERNAME_PATTERN})\Z/o.match(CGI.unescape(path))
    @username = match[1] if match.present?
    match.present?
  end
end
