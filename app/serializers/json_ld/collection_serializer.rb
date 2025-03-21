module JsonLd
  class CollectionSerializer < ApplicationSerializer
    def serialize
      {
        "@context": "https://schema.org/Collection",
        "@id": Rails.application.routes.url_helpers.collection_path(@object),
        "@type": "Collection",
        name: @object.name,
        description: @object.notes
      }
    end
  end
end
