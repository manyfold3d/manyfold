module ManyfoldApi::V0
  class ModelListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Rails.application.routes.url_helpers.models_path,
        "@type": "hydra:Collection",
        totalItems: @object.total_count,
        member: @object.map { |model|
          model_ref(model).merge(
            name: model.name
          )
        },
        view: {
          "@id": Rails.application.routes.url_helpers.models_path(page: @object.current_page),
          "@type": "hydra:PartialCollectionView",
          first: Rails.application.routes.url_helpers.models_path(page: 1),
          previous: (Rails.application.routes.url_helpers.models_path(page: @object.prev_page) if @object.prev_page),
          next: (Rails.application.routes.url_helpers.models_path(page: @object.next_page) if @object.next_page),
          last: Rails.application.routes.url_helpers.models_path(page: @object.total_pages)
        }.compact
      }
    end
  end
end
