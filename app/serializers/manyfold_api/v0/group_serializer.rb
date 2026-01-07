module ManyfoldApi::V0
  class GroupSerializer < ApplicationSerializer
    def serialize
      group_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.description
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/creators/abc123/groups/1"},
          "@type": {type: :string, example: "Group"}
        }.merge(GroupDeserializer.schema[:properties]),
        required: ["@context", "@id", "@type"]
      }
    end
  end
end
