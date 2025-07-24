class Integrations::Thangs::ModelDeserializer < Integrations::Thangs::BaseDeserializer
  attr_reader :model_id

  def deserialize
    return {} unless valid?
    r = fetch "models/#{CGI.escapeURIComponent(@model_id)}"
    files = r.body.dig("attachments").filter_map { |it| {url: it.dig("imageUrl"), filename: filename_from_url(it.dig("imageUrl"))} if it.dig("attachmentType") == "image" }
    {
      name: r.body["name"],
      notes: r.body["description"],
      file_urls: files,
      preview_filename: files.first&.dig(:filename)
    }.merge(creator_attributes(r.body["owner"]))
  end

  def capabilities
    {
      class: Model,
      name: true,
      notes: true,
      images: true,
      model_files: false,
      creator: true,
      tags: false,
      sensitive: false,
      license: false
    }
  end

  private

  def valid_path?(path)
    match = /\A\/designer\/#{PATH_COMPONENTS[:username]}\/3d-model\/#{PATH_COMPONENTS[:model_slug]}-#{PATH_COMPONENTS[:model_id]}\Z/.match(CGI.unescape(path))
    @model_id = match[:model_id] if match.present?
    match.present?
  end

  def creator_attributes(data)
    return {} if data.nil? || data["username"].nil?
    url = "https://thangs.com/designer/#{data["username"]}"
    c = Creator.linked_to(url).first
    return {creator: c} if c
    {creator_attributes: Integrations::Thangs::CreatorDeserializer.parse(data)}
  end
end
