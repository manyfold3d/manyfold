module ActivityPub
  class ApplicationDeserializer < BaseDeserializer
    def self.deserializer_for(object)
      case object.extensions&.dig("f3di:concreteType")
      when "Creator"
        ActivityPub::CreatorDeserializer.new(object)
      when "3DModel"
        ActivityPub::ModelDeserializer.new(object)
      when "Collection"
        ActivityPub::CollectionDeserializer.new(object)
      end
    end

    def update!
      @object.entity.update!(deserialize)
    end

    private

    def parse_link_attributes(object)
      links = object.extensions&.dig("attachment") || []
      links.select { |it| it["type"] == "Link" }&.map { |it| {url: it["href"]} }
    end
  end
end
