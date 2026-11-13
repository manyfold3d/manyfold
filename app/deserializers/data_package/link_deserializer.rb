module DataPackage
  class LinkDeserializer < BaseDeserializer
    def deserialize
      return unless @object && UrlSafety.public?(@object["path"])
      {
        url: @object["path"],
        text: @object["text"]
      }.compact
    end
  end
end
