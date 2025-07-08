class Integrations::MyMiniFactory::ModelDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  attr_reader :object_id

  def deserialize
    return {} unless valid?
    # Fetch from MMF API
    connection = Faraday.new do |builder|
      builder.response :json
    end
    r = connection.get("https://www.myminifactory.com/api/v2/objects/#{CGI.escapeURIComponent(@object_id)}",
      {key: @api_key},
      {Accept: "application/json"})
    {
      name: r.body["name"],
      notes: ReverseMarkdown.convert(r.body["description_html"]),
      tag_list: r.body["tags"],
      image_urls: r.body["images"].map { |it| it.dig("original", "url") }
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
