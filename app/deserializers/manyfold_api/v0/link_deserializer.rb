module ManyfoldApi::V0
  class LinkDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        url: @object["url"]
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          url: {type: :string, example: "https://example.com"}
        },
        required: ["url"]
      }
    end
  end
end
