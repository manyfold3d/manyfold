class Integrations::Thingiverse::ModelDeserializer < Integrations::Thingiverse::BaseDeserializer
  attr_reader :object_id

  def deserialize
    return {} unless valid?
    r = fetch "things/#{CGI.escapeURIComponent(@object_id)}"
    {
      name: r.body["name"],
      notes: r.body["description"],
      tag_list: r.body["tags"]&.pluck("tag"),
      sensitive: r.body["is_nsfw"],
      file_urls:
        r.body.dig("zip_data", "images").map { |it| {url: it.dig("url"), filename: "images/" + filename_from_url(it.dig("url"))} } +
          r.body.dig("zip_data", "files").map { |it| {url: it.dig("url"), filename: "files/" + filename_from_url(it.dig("url"))} },
      preview_filename: "images/" + r.body.dig("default_image", "name")
    }.merge(creator_attributes(r.body["creator"]))
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

  def creator_attributes(data)
    return {} if data.nil? || data["public_url"].nil?
    c = Creator.linked_to(data["public_url"]).first
    return {creator: c} if c
    {creator_attributes: Integrations::Thingiverse::CreatorDeserializer.parse(data)}
  end
end
