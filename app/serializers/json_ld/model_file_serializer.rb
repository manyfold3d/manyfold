module JsonLd
  class ModelFileSerializer < ApplicationSerializer
    def serialize
      {
        "@context": [
          "https://schema.org/3DModel",
          "https://spdx.org/rdf/3.0.0/spdx-context.jsonld"
        ],
        "@id": Rails.application.routes.url_helpers.model_model_file_path(@object.model, @object),
        "@type": "3DModel",
        name: @object.name,
        isPartOf: Rails.application.routes.url_helpers.model_path(@object.model),
        contentUrl: Rails.application.routes.url_helpers.model_model_file_path(@object.model, @object, format: @object.extension),
        encodingFormat: @object.mime_type.to_s,
        contentSize: @object.size,
        description: @object.notes,
        license: license(@object.model.license)
      }.compact
    end
  end
end
