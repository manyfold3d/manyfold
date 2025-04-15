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
        caption: @object.caption,
        presupported: @object.presupported,
        up: @object.up_direction,
        related: [
          @object.presupported_version ? file_ref(@object.presupported_version).merge(relationship: "presupported_version") : nil,
          @object.unsupported_version ? file_ref(@object.unsupported_version).merge(relationship: "presupported_version_of") : nil
        ].compact,
        "spdx:license": license(@object.model.license),
        creator: creator_ref(@object.model.creator)
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          # JSON-LD
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
          "@type": {type: :string, example: "3DModel"},
          # Derived attributes
          name: {type: :string, example: "Benchy"},
          encodingFormat: {type: :string, example: "model/stl"},
          contentUrl: {type: :string, example: "https://example.com/models/abc123/model_files/def456.stl"},
          contentSize: {type: :integer, example: 12345},
          # Attributes from model
          isPartOf: {type: :object, properties: {
            "@id": {type: :string, example: "https://example.com/models/abc123"},
            "@type": {type: :string, example: "3DModel"}
          }},
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

  private

  def related_ref(object, relationship)
  end
end
