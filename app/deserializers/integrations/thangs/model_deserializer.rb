class Integrations::Thangs::ModelDeserializer < Integrations::Thangs::BaseDeserializer
  attr_reader :object_id

  def deserialize
    return {} unless valid?
    r = fetch "models/#{CGI.escapeURIComponent(@object_id)}"
    {
      name: r.body["name"],
      notes: r.body["description"],
      file_urls:
        r.body.dig("attachments").filter_map { |it| {url: it.dig("imageUrl"), filename: filename_from_url(it.dig("imageUrl"))} if it.dig("attachmentType") == "image" }
    }
  end

  private

  def target_class
    Model
  end

  def valid_path?(path)
    match = /\A\/designer\/#{PATH_COMPONENTS[:username]}\/3d-model\/#{PATH_COMPONENTS[:model_slug]}-#{PATH_COMPONENTS[:model_id]}\Z/.match(CGI.unescape(path))
    @object_id = match[:model_id] if match.present?
    match.present?
  end
end
