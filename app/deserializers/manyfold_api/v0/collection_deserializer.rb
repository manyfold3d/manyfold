module ManyfoldApi::V0
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        notes: @object["description"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Interesting Things"},
          description: {type: :string, example: "Lorem ipsum dolor sit amet...", description: "A longer description for the collection. Can contain Markdown syntax."}
        },
        required: ["name"]
      }
    end
  end
end
