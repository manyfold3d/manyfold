module DataPackage
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      {
        filename: @object["path"],
        mime_type: @object["mediatype"]
      }
    end
  end
end
