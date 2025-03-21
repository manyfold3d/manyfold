module JsonLd
  class ModelSerializer < ApplicationSerializer
    def serialize
      {
        "@context": "https://schema.org/3DModel",
        "@id": Rails.application.routes.url_helpers.model_path(@object),
        "@type": "3DModel",
        name: @object.name,
        description: @object.notes,
        hasPart: @object.model_files.without_special.map do |file|
          {
            "@type": "3DModel",
            "@id": Rails.application.routes.url_helpers.model_model_file_path(@object, file),
            name: file.name,
            encodingFormat: file.mime_type.to_s
          }
        end
      }
    end
  end
end
