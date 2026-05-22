module Form
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      params = @params.require(:model_file).permit([
        :filename, # i18n-tasks-use t("activerecord.attributes.model_file.filename")
        :presupported, # i18n-tasks-use t("activerecord.attributes.model_file.presupported")
        # printed isn't actually deserialized here but we'll include the form attribute anyway
        # i18n-tasks-use t("activerecord.attributes.model_file.printed")
        :notes, # i18n-tasks-use t("activerecord.attributes.model_file.notes")
        :caption, # i18n-tasks-use t("activerecord.attributes.model_file.caption")
        :y_up, # i18n-tasks-use t("activerecord.attributes.model_file.y_up")
        :previewable, # i18n-tasks-use t("activerecord.attributes.model_file.previewable")
        :presupported_version_id # i18n-tasks-use t("activerecord.attributes.model_file.presupported_version_id")
      ])
      if (id = params.delete("presupported_version_id"))
        if (file = @record.model.model_files.find(id))
          params[:reverse_relationships_attributes] = [{
            subject: file,
            predicate: "supported_version_of"
          }]
        end
      end
      params
    end
  end
end
