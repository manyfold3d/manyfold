module ManyfoldApi::V0
  class ModelListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Rails.application.routes.url_helpers.models_path,
        "@type": "hydra:Collection",
        totalItems: @pager.count,
        member: @object.map { |model|
          model_ref(model).merge(
            name: model.name
          )
        },
        view: {
          "@id": Rails.application.routes.url_helpers.models_path(page: @pager.page),
          "@type": "hydra:PartialCollectionView",
          first: Rails.application.routes.url_helpers.models_path(page: 1),
          previous: (Rails.application.routes.url_helpers.models_path(page: @pager.previous) if @pager.previous),
          next: (Rails.application.routes.url_helpers.models_path(page: @pager.next) if @pager.next),
          last: Rails.application.routes.url_helpers.models_path(page: @pager.pages)
        }.compact
      }
    end
  end
end
