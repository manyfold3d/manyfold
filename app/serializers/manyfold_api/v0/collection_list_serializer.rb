module ManyfoldApi::V0
  class CollectionListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Rails.application.routes.url_helpers.collections_path,
        "@type": "hydra:Collection",
        totalItems: @pager.count,
        member: @object.map { |collection|
          {
            "@id": Rails.application.routes.url_helpers.collection_path(collection),
            name: collection.name
          }
        },
        view: {
          "@id": Rails.application.routes.url_helpers.collections_path(page: @pager.page),
          "@type": "hydra:PartialCollectionView",
          first: Rails.application.routes.url_helpers.collections_path(page: 1),
          previous: (Rails.application.routes.url_helpers.collections_path(page: @pager.previous) if @pager.previous),
          next: (Rails.application.routes.url_helpers.collections_path(page: @pager.next) if @pager.next),
          last: Rails.application.routes.url_helpers.collections_path(page: @pager.pages)
        }.compact
      }
    end
  end
end
