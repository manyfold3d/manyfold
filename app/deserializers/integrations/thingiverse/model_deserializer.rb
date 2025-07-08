class Integrations::Thingiverse::ModelDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :object_id

  def deserialize
    return {} unless valid?
    # Fetch from MMF API
    connection = Faraday.new do |builder|
      builder.response :json
    end
    r = connection.get("https://api.thingiverse.com/things/#{CGI.escapeURIComponent(@object_id)}",
      {},
      {
        Authorization: "Bearer #{@api_key}",
        Accept: "application/json"
      })
    {
      name: r.body["name"],
      notes: ReverseMarkdown.convert(r.body["description"]),
      tag_list: r.body["tags"]&.pluck("tag"),
      sensitive: r.body["is_nsfw"]
      # image_urls: r.body["images"].map { |it| it.dig("original", "url") }
    }
  end

  private

  def target_class
    Model
  end

  def valid_path?(path)
    match = /\A\/thing:([[:digit:]]+)\Z/.match(path)
    @object_id = match[1] if match.present?
    match.present?
  end
end
