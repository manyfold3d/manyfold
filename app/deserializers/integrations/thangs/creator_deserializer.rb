class Integrations::Thangs::CreatorDeserializer < Integrations::MyMiniFactory::BaseDeserializer
  def self.parse(data)
    {
      name: data["username"],
      notes: ReverseMarkdown.convert(data.dig("profile", "description")),
      links_attributes: [{url: "https://thangs.com/designer/#{data["username"]}"}]
    }
  end

  private

  def target_class
    Creator
  end
end
