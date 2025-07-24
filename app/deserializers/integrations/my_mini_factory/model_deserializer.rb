class Integrations::MyMiniFactory::ModelDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :model_id

  def deserialize
    return {} unless valid?
    # Fetch from MMF API
    r = fetch "objects/#{CGI.escapeURIComponent(@model_id)}"
    {
      name: r.body["name"],
      slug: @slug,
      notes: ReverseMarkdown.convert(r.body["description_html"]),
      tag_list: r.body["tags"],
      file_urls: r.body["images"]&.map { |it| {url: it.dig("original", "url"), filename: filename_from_url(it.dig("original", "url"))} },
      preview_filename: filename_from_url(r.body["images"]&.find { |it| it["is_primary"] === true }&.dig("original", "url"))
    }.merge(creator_attributes(r.body["designer"]))
  end

  def capabilities
    {
      class: Model,
      name: true,
      notes: true,
      images: true,
      model_files: false,
      creator: true,
      tags: true,
      sensitive: false,
      license: false
    }
  end

  private

  def valid_path?(path)
    match = /\A\/object\/3d-print-(?<slug>[[:alnum:]-]+)-(?<model_id>[[:digit:]]+)\Z/.match(path)
    if match.present?
      @model_id = match[:model_id]
      @slug = match[:slug]
    end
    match.present?
  end
end
