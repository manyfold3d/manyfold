module JsonLd
  class ModelSerializer < ApplicationSerializer
    def serialize
      {
        "@context": "https://schema.org/3DModel",
        "@id": Rails.application.routes.url_helpers.model_path(@object),
        "@type": "3DModel",
        name: @object.name,
        description: @object.notes
      }
    end
  end
end
