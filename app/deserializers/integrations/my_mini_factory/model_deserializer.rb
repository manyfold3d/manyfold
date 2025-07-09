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
      file_urls: (r.body["images"].map { |it| {url: it.dig("original", "url"), filename: filename_from_url(it.dig("original", "url"))} } +
                  r.body.dig("files", "items").map { |it| {url: it.dig("download_url"), filename: it.dig("filename")} }),
      preview_filename: filename_from_url(r.body["images"].find { |it| it["is_primary"] === true }&.dig("original", "url"))
    }
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
end
