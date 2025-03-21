module JsonLd
  class ModelListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Rails.application.routes.url_helpers.models_path,
        "@type": "Collection",
        totalItems: @object.total_count,
        member: @object.map { |model|
          {
            "@id": Rails.application.routes.url_helpers.model_path(model),
            name: model.name
          }
        },
        view: {
          "@id": Rails.application.routes.url_helpers.models_path(page: @object.current_page),
          "@type": "PartialCollectionView",
          first: Rails.application.routes.url_helpers.models_path(page: 1),
          previous: (Rails.application.routes.url_helpers.models_path(page: @object.prev_page) if @object.prev_page),
          next: (Rails.application.routes.url_helpers.models_path(page: @object.next_page) if @object.next_page),
          last: Rails.application.routes.url_helpers.models_path(page: @object.total_pages)
        }.compact
      }
    end
  end
end
