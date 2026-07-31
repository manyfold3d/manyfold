module ManyfoldApi::V0
  class CollectionListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Amiko.application.routes.url_helpers.collections_path,
        "@type": "hydra:Collection",
        totalItems: @pager.count,
        member: @object.map { |collection|
          {
            "@id": Amiko.application.routes.url_helpers.collection_path(collection),
            name: collection.name
          }
        },
        view: {
          "@id": Amiko.application.routes.url_helpers.collections_path(page: @pager.page),
          "@type": "hydra:PartialCollectionView",
          first: Amiko.application.routes.url_helpers.collections_path(page: 1),
          previous: (Amiko.application.routes.url_helpers.collections_path(page: @pager.previous) if @pager.previous),
          next: (Amiko.application.routes.url_helpers.collections_path(page: @pager.next) if @pager.next),
          last: Amiko.application.routes.url_helpers.collections_path(page: @pager.pages)
        }.compact
      }
    end
  end
end
