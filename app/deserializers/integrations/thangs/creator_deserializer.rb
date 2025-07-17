class Integrations::Thangs::CreatorDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  def self.parse(data)
    {
      name: data["username"],
      notes: ReverseMarkdown.convert(data.dig("profile", "description")),
      links_attributes: [{url: "https://thangs.com/designer/#{data["username"]}"}]
    }
  end

  def capabilities
    {
      class: Creator,
      name: true,
      notes: true
    }
  end
end
