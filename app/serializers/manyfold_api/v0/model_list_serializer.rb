module ManyfoldApi::V0
  class ModelListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": context,
        "@id": Amiko.application.routes.url_helpers.models_path,
        "@type": "hydra:Collection",
        totalItems: @pager.count,
        member: @object.map { |model|
          model_ref(model).merge(
            name: model.name
          )
        },
        view: {
          "@id": Amiko.application.routes.url_helpers.models_path(page: @pager.page),
          "@type": "hydra:PartialCollectionView",
          first: Amiko.application.routes.url_helpers.models_path(page: 1),
          previous: (Amiko.application.routes.url_helpers.models_path(page: @pager.previous) if @pager.previous),
          next: (Amiko.application.routes.url_helpers.models_path(page: @pager.next) if @pager.next),
          last: Amiko.application.routes.url_helpers.models_path(page: @pager.pages)
        }.compact
      }
    end
  end
end
