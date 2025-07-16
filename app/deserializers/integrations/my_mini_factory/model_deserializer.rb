class Integrations::MyMiniFactory::ModelDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :object_id

  def deserialize
    return {} unless valid?
    # Fetch from MMF API
    r = fetch "objects/#{CGI.escapeURIComponent(@object_id)}"
    {
      name: r.body["name"],
      notes: ReverseMarkdown.convert(r.body["description_html"]),
      tag_list: r.body["tags"],
      file_urls: r.body["images"]&.map { |it| {url: it.dig("original", "url"), filename: filename_from_url(it.dig("original", "url"))} },
      preview_filename: filename_from_url(r.body["images"]&.find { |it| it["is_primary"] === true }&.dig("original", "url"))
    }.merge(creator_attributes(r.body["designer"]))
  end

  private

  def target_class
    Model
  end

  def valid_path?(path)
    match = /\A\/object\/3d-print-[[:alnum:]-]+-([[:digit:]]+)\Z/.match(path)
    @object_id = match[1] if match.present?
    match.present?
  end

  def creator_attributes(data)
    return {} if data.nil? || data["profile_url"].nil?
    c = Creator.linked_to(data["profile_url"]).first
    return {creator: c} if c
    {creator_attributes: Integrations::MyMiniFactory::CreatorDeserializer.parse(data)}
  end
end
