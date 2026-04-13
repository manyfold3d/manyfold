module Form
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.require(:model_file).permit([
        :filename, # i18n-tasks-use t("activerecord.attributes.model_file.filename")
        :presupported, # i18n-tasks-use t("activerecord.attributes.model_file.presupported")
        :notes, # i18n-tasks-use t("activerecord.attributes.model_file.notes")
        :caption, # i18n-tasks-use t("activerecord.attributes.model_file.caption")
        :y_up, # i18n-tasks-use t("activerecord.attributes.model_file.y_up")
        :previewable, # i18n-tasks-use t("activerecord.attributes.model_file.previewable")
        :presupported_version_id # i18n-tasks-use t("activerecord.attributes.model_file.presupported_version")
      ])
    end
  end
end
