module ManyfoldApi::V0
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        notes: @object["description"]
      }.compact
    end
  end
end
