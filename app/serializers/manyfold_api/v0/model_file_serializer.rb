module ManyfoldApi::V0
  class ModelFileSerializer < ApplicationSerializer
    def serialize
      file_ref(@object).merge(
        "@context": context,
        name: @object.name,
        isPartOf: model_ref(@object.model),
        contentUrl: Rails.application.routes.url_helpers.model_model_file_path(@object.model, @object, format: @object.extension),
        encodingFormat: @object.mime_type.to_s,
        contentSize: @object.size,
        description: @object.notes,
        "spdx:license": license(@object.model.license),
        creator: creator_ref(@object.model.creator)
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
          "@type": {type: :string, example: "3DModel"},
          name: {type: :string, example: "Benchy"},
          isPartOf: {type: :object, properties: {
            "@id": {type: :string, example: "https://example.com/models/abc123"},
            "@type": {type: :string, example: "3DModel"}
          }},
          encodingFormat: {type: :string, example: "model/stl"},
          contentUrl: {type: :string, example: "https://example.com/models/abc123/model_files/def456.stl"},
          contentSize: {type: :integer, example: 12345},
          "spdx:license": {"$ref" => "#/components/schemas/spdxLicense"},
          creator: {
            type: :object,
            properties: {
              "@id": {type: :string, example: "https://example.com/creators/abc123"},
              "@type": {type: :string, example: "Organization"}
            }
          }
        }.merge(ModelFileDeserializer.schema[:properties]),
        required: ["@context", "@id", "@type", "isPartOf", "encodingFormat"]
      }
    end
  end
end
