module ManyfoldApi::V0
  class ModelDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        notes: @object["description"],
        license: @object.dig("spdx:License", "licenseId")
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Batmobile"},
          description: {type: :string, example: "Lorem ipsum dolor sit amet..."}, # rubocop:disable I18n/RailsI18n/DecorateString
          "spdx:license": {"$ref" => "#/components/schemas/spdxLicense"}
        },
        required: ["name"]
      }
    end
  end
end
