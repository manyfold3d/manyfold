class Integrations::Thingiverse::ModelDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :object_id

  def deserialize
    return {} unless valid?
    r = fetch "things/#{CGI.escapeURIComponent(@object_id)}"
    {
      name: r.body["name"],
      notes: r.body["description"],
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
