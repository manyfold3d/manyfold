module ManyfoldApi::V0
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        filename: @object["filename"],
        notes: @object["description"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          filename: {type: :string, example: "model.stl"},
          description: {type: :string, example: "Lorem ipsum dolor sit amet..."}
        }
      }
    end
  end
end
