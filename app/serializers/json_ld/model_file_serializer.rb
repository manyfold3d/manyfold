module JsonLd
  class ModelFileSerializer < ApplicationSerializer
    def serialize
      file_ref(@object).merge(
        "@context": context,
        name: @object.name,
        isPartOf: model_ref(@object.model),
        contentUrl: Rails.application.routes.url_helpers.model_model_file_path(@object.model, @object, format: @object.extension),
        encodingFormat: @object.mime_type.to_s,
        contentSize: @object.size,
        description: @object.notes,
        "spdx:license": license(@object.model.license),
        creator: creator_ref(@object.model.creator)
      ).compact
    end
  end
end
