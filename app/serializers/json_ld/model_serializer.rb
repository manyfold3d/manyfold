module JsonLd
  class ModelSerializer < ApplicationSerializer
    def serialize
      model_ref(@object).merge(
        "@context": [
          "https://schema.org/3DModel",
          "https://spdx.org/rdf/3.0.0/spdx-context.jsonld"
        ],
        name: @object.name,
        description: @object.notes,
        license: license(@object.license),
        hasPart: @object.model_files.without_special.map do |file|
          file_ref(file).merge(
            name: file.name,
            encodingFormat: file.mime_type.to_s
          )
      ).compact
    end
  end
end
