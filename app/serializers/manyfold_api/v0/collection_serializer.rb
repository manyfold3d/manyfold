module ManyfoldApi::V0
  class CollectionSerializer < ApplicationSerializer
    def serialize
      collection_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.notes,
        creator: creator_ref(@object.creator),
        isPartOf: collection_ref(@object.collection)
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/collections/abc123"},
          "@type": {type: :string, example: "Collection"}
        }.merge(CollectionDeserializer.schema[:properties]),
        required: ["@context", "@id", "@type"]
      }
    end
  end
end
