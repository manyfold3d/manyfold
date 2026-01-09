module ManyfoldApi::V0
  class GroupSerializer < ApplicationSerializer
    def serialize
      group_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.description,
        members: @object.members.map(&:username)
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/creators/abc123/groups/1"},
          "@type": {type: :string, example: "Group"},
          members: {type: :array, items: {type: :string, example: "username"}}
        }.merge(GroupDeserializer.schema[:properties]),
        required: ["@context", "@id", "@type"]
      }
    end
  end
end
