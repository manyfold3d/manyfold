module Form
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:model_file).permit([
        :filename, # i18n-tasks-use t("activerecord.attributes.model_file.filename")
        :presupported, # i18n-tasks-use t("activerecord.attributes.model_file.presupported")
        # printed isn't actually deserialized here but we'll include the form attribute anyway
        # i18n-tasks-use t("activerecord.attributes.model_file.printed")
        :notes, # i18n-tasks-use t("activerecord.attributes.model_file.notes")
        :caption, # i18n-tasks-use t("activerecord.attributes.model_file.caption")
        :y_up, # i18n-tasks-use t("activerecord.attributes.model_file.y_up")
        :previewable, # i18n-tasks-use t("activerecord.attributes.model_file.previewable")
        relationships_attributes: [:id, :predicate, :objekt_id, :_destroy] # i18n-tasks-use t("activerecord.attributes.model_file.relationships")
      ])
      if allowed[:relationships_attributes]
        allowed[:relationships_attributes] = allowed[:relationships_attributes].to_h.map do |k, attrs|
          attrs[:objekt] = @record.model.model_files.find_param(attrs.delete(:objekt_id)) if attrs[:objekt_id] && attrs[:id].nil?
          attrs
        end
      end
      allowed
    end
  end
end
