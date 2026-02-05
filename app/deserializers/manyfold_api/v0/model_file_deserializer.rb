module ManyfoldApi::V0
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        filename: @object["filename"],
        notes: @object["description"],
        caption: @object["caption"],
        presupported: @object["presupported"],
        y_up: @object["up"] == "+y",
        previewable: @object["presupported"],
        presupported_version: dereference(@object["related"]&.find { |it| it["relationship"] == "presupported_version" }&.dig("@id"), ModelFile)
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          filename: {type: :string, example: "model.stl"},
          description: {type: :string, example: "Lorem ipsum dolor sit amet..."}, # rubocop:disable I18n/RailsI18n/DecorateString
          caption: {type: :string, example: "A short caption describing the file"},
          presupported: {type: :boolean, example: true},
          up: {type: :string, enum: ["+y", "+z"], example: "+y"},
          previewable: {type: :boolean, example: false},
          related: {
            type: :array,
            items: {
              type: :object,
              properties: {
                "@id": {type: :string, example: "https://example.com/models/abc123/model_files/def456"},
                "@type": {type: :string, example: "3DModel"},
                relationship: {type: :string, enum: ["presupported_version", "presupported_version_of"], example: "presupported_version"}
              }
            }
          }
        }
      }
    end
  end
end
