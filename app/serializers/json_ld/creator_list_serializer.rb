module JsonLd
  class CreatorListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": "http://www.w3.org/ns/hydra/context.jsonld",
        "@id": Rails.application.routes.url_helpers.creators_path,
        "@type": "Collection",
        totalItems: @object.total_count,
        member: @object.map { |creator|
          {
            "@id": Rails.application.routes.url_helpers.creator_path(creator),
            name: creator.name
          }
        },
        view: {
          "@id": Rails.application.routes.url_helpers.creators_path(page: @object.current_page),
          "@type": "PartialCollectionView",
          first: Rails.application.routes.url_helpers.creators_path(page: 1),
          previous: (Rails.application.routes.url_helpers.creators_path(page: @object.prev_page) if @object.prev_page),
          next: (Rails.application.routes.url_helpers.creators_path(page: @object.next_page) if @object.next_page),
          last: Rails.application.routes.url_helpers.creators_path(page: @object.total_pages)
        }.compact
      }
    end
  end
end
