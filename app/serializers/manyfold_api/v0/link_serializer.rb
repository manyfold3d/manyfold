module ManyfoldApi::V0
  class LinkSerializer < ApplicationSerializer
    def serialize
      {
        url: @object.url
      }.compact
    end

    def self.schema
      LinkDeserializer.schema
    end
  end
end
