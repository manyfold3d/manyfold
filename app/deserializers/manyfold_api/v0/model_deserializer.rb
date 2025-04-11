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
  end
end
