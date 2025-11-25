module ManyfoldApi::V0
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        creator: dereference(@object.dig("creator", "@id"), Creator),
        collection: dereference(@object.dig("isPartOf", "@id"), Collection),
        caption: @object["caption"],
        notes: @object["description"],
        links_attributes: @object["links"]&.map { |it| LinkDeserializer.new(object: it, user: @user).deserialize }
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Interesting Things"},
          caption: {type: :string, example: "A short description"},
          description: {type: :string, example: "Lorem ipsum dolor sit amet..."}, # rubocop:disable I18n/RailsI18n/DecorateString
          links: {
            type: :array,
            items: LinkDeserializer.schema_ref
          },
          creator: {
            type: :object,
            properties: {
              "@id": {type: :string, example: "https://example.com/creators/abc123"},
              "@type": {type: :string, example: "Organization"}
            },
            required: ["@id"]
          },
          isPartOf: {
            type: :object,
            properties: {
              "@id": {type: :string, example: "https://example.com/collections/abc123"},
              "@type": {type: :string, example: "Collection"}
            },
            required: ["@id"]
          }
        },
        required: ["name"]
      }
    end
  end
end
