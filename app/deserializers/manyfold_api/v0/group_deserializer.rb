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
          description: {type: :string, example: "My subscribers"},
          add_members: {type: :array, items: {type: :string, example: "username"}},
          remove_members: {type: :array, items: {type: :string, example: "username"}}
        }
      }
    end
  end
end
