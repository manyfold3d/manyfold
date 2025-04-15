module ManyfoldApi::V0
  class CreatorSerializer < ApplicationSerializer
    def serialize
      creator_ref(@object).merge(
        "@context": context,
        name: @object.name,
        slug: @object.slug,
        caption: @object.caption,
        description: @object.notes,
        links: @object.links.map { |it| LinkSerializer.new(it).serialize }
      ).compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          "@context": {"$ref" => "#/components/schemas/jsonld_context"},
          "@id": {type: :string, example: "https://example.com/creators/abc123"},
          "@type": {type: :string, example: "Organization"}
        }.merge(CreatorDeserializer.schema[:properties]),
        required: ["@context", "@id", "@type"]
      }
    end
  end
end
