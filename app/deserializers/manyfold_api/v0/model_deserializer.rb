module ManyfoldApi::V0
  class ModelDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        creator: dereference(@object.dig("creator", "@id"), Creator),
        collection: dereference(@object.dig("isPartOf", "@id"), Collection),
        caption: @object["caption"],
        notes: @object["description"],
        links_attributes: @object["links"]&.map { |it| LinkDeserializer.new(object: it, user: @user).deserialize },
        license: @object.dig("spdx:license", "licenseId"),
        sensitive: @object["sensitive"],
        preview_file: dereference(@object.dig("preview_file", "@id"), ModelFile),
        tag_list: @object["keywords"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Batmobile"},
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
          },
          "spdx:license": {"$ref" => "#/components/schemas/spdxLicense"},
          sensitive: {type: :boolean, example: true},
          keywords: {type: :array, items: {type: :string, example: "tag"}},
          preview_file: {
            type: :object,
            properties: {
              "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
              "@type": {type: :string, example: "3DModel"}
            },
            required: ["@id"]
          }
        },
        required: ["name"]
      }
    end
  end
end
