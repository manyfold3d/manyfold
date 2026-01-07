module ManyfoldApi::V0
  class GroupDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        description: @object["description"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Patrons"},
          description: {type: :string, example: "My subscribers"}
        },
        required: ["name"]
      }
    end
  end
end
