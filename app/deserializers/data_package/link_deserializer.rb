module DataPackage
  class LinkDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        url: @object["path"]
      }.compact
    end
  end
end
