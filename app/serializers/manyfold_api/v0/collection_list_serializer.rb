module ManyfoldApi::V0
  class CollectionListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Amiko.application.routes.url_helpers.collections_path,
        "@type": "hydra:Collection",
        totalItems: @object.total_count,
        member: @object.map { |collection|
          {
            "@id": Amiko.application.routes.url_helpers.collection_path(collection),
            name: collection.name
          }
        },
        view: {
          "@id": Amiko.application.routes.url_helpers.collections_path(page: @object.current_page),
          "@type": "hydra:PartialCollectionView",
          first: Amiko.application.routes.url_helpers.collections_path(page: 1),
          previous: (Amiko.application.routes.url_helpers.collections_path(page: @object.prev_page) if @object.prev_page),
          next: (Amiko.application.routes.url_helpers.collections_path(page: @object.next_page) if @object.next_page),
          last: Amiko.application.routes.url_helpers.collections_path(page: @object.total_pages)
        }.compact
      }
    end
  end
end
