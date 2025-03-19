module JsonLd
  class ModelListSerializer < ApplicationSerializer
    def serialize
      {
        "@context": "http://www.w3.org/ns/hydra/context.jsonld",
        "@id": Rails.application.routes.url_helpers.models_path,
        "@type": "Collection",
        totalItems: @object.total_count,
        member: @object.map do |model|
          {
            "@id": Rails.application.routes.url_helpers.model_path(model),
            name: model.name
          }
        end
      }
    end
  end
end
