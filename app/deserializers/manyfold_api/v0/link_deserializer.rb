module ManyfoldApi::V0
  class LinkDeserializer < BaseDeserializer
    def deserialize
      return unless @object && UrlSafety.public?(@object["url"])
      {
        url: @object["url"],
        text: @object["text"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          url: {type: :string, example: "https://example.com"},
          text: {type: :string, example: "anchor text"}
        },
        required: ["url"]
      }
    end
  end
end
