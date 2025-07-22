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
        r.body.dig("zip_data", "images").map { |it| {url: it.dig("url"), filename: "images/" + it.dig("name")} } +
          r.body.dig("zip_data", "files").map { |it| {url: it.dig("url"), filename: "files/" + it.dig("name")} },
      preview_filename: "images/" + r.body.dig("default_image", "name")
    }.merge(creator_attributes(r.body["creator"]))
  end

  def capabilities
    {
      class: Model,
      name: true,
      notes: true,
      images: true,
      model_files: true,
      creator: true,
      tags: true,
      sensitive: true,
      license: false
    }
  end

  private

  def valid_path?(path)
    match = /\A\/thing:([[:digit:]]+)\Z/.match(path)
    @object_id = match[1] if match.present?
    match.present?
  end
end
