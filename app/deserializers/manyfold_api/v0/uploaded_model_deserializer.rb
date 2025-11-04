module ManyfoldApi::V0
  class UploadedModelDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        file: @object.dig("files")&.each_with_index.to_h.invert,
        creator_id: dereference(@object.dig("creator", "@id"), Creator)&.id,
        collection_id: dereference(@object.dig("isPartOf", "@id"), Collection)&.id,
        license: @object.dig("spdx:license", "licenseId"),
        sensitive: @object["sensitive"] ? "1" : "0",
        tags: @object["keywords"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "My New Model", description: "Used as model name if any files are uploaded that aren't compressed archives"},
          files: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: {type: :string, description: "The ID of a completed upload, obtained from the upload endpoints", example: "http://example.com/uploads/abc123456def"},
                name: {type: :string, example: "model.stl"}
              },
              required: [:id, :name, :type, :size]
            }
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
          keywords: {type: :array, items: {type: :string, example: "tag"}}
        },
        required: [:files]
      }
    end
  end
end
