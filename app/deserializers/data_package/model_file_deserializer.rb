module DataPackage
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      {
        filename: @object["path"],
        mime_type: @object["mediatype"],
        caption: @object["caption"],
        notes: @object["description"],
        presupported: @object["presupported"],
        y_up: (@object["up"] == "+y")
      }.compact
    end
  end
end
