module ManyfoldApi::V0
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        filename: @object["filename"],
        notes: @object["description"]
      }.compact
    end
  end
end
