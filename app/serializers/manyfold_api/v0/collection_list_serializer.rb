module ManyfoldApi::V0
  class CollectionListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Mosscap.application.routes.url_helpers.collections_path,
        "@type": "hydra:Collection",
        totalItems: @pager.count,
        member: @object.map { |collection|
          {
            "@id": Mosscap.application.routes.url_helpers.collection_path(collection),
            name: collection.name
          }
        },
        view: {
          "@id": Mosscap.application.routes.url_helpers.collections_path(page: @pager.page),
          "@type": "hydra:PartialCollectionView",
          first: Mosscap.application.routes.url_helpers.collections_path(page: 1),
          previous: (Mosscap.application.routes.url_helpers.collections_path(page: @pager.previous) if @pager.previous),
          next: (Mosscap.application.routes.url_helpers.collections_path(page: @pager.next) if @pager.next),
          last: Mosscap.application.routes.url_helpers.collections_path(page: @pager.pages)
        }.compact
      }
    end
  end
end
