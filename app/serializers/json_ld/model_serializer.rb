module JsonLd
  class ModelSerializer < ApplicationSerializer
    def serialize
      model_ref(@object).merge(
        "@context": context,
        name: @object.name,
        description: @object.notes,
        "spdx:license": license(@object.license),
        hasPart: @object.model_files.without_special.map do |file|
          file_ref(file).merge(
            name: file.name,
            encodingFormat: file.mime_type.to_s
          )
        end,
        isPartOf: collection_ref(@object.collection),
      ).compact
    end
  end
end
