module ManyfoldApi::V0
  class ModelSerializer < ApplicationSerializer
    def serialize
      model_ref(@object).merge(
        "@context": context,
        name: @object.name,
        caption: @object.caption,
        description: @object.notes,
        "spdx:license": license(@object.license),
        hasPart: @object.model_files.without_special.map do |file|
          file_ref(file).merge(
            name: file.name,
            encodingFormat: file.mime_type.to_s
          )
        end,
        isPartOf: collection_ref(@object.collection),
        creator: creator_ref(@object.creator),
        sensitive: @object.sensitive,
        keywords: @object.tag_list,
        preview_file: file_ref(@object.preview_file),
        links: @object.links.map { |it| LinkSerializer.new(it).serialize }
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/models/abc123"},
          "@type": {type: :string, example: "3DModel"},
          hasPart: {
            type: :array,
            items: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
                "@type": {type: :string, example: "3DModel"},
                name: {type: :string, example: "Benchy"},
                encodingFormat: {type: :string, example: "model/stl"}
              }
            },
            required: ["@id", "@type", "name", "encodingFormat"]
          }
        }.merge(ModelDeserializer.schema[:properties]),
        required: ["@context", "@id", "@type", "hasPart"]
      }
    end
  end
end
