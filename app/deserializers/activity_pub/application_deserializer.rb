module ActivityPub
  class ApplicationDeserializer < BaseDeserializer
    private

    def parse_link_attributes(object)
      links = object.extensions&.dig("attachment") || []
      links.select { |it| it["type"] == "Link" }&.map { |it| {url: it["href"]} }
    end
  end
end
