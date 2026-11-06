module Form
  class ModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:model).permit(
        :preview_file, # i18n-tasks-use t("activerecord.attributes.model.preview_file")
        :creator, # i18n-tasks-use t("activerecord.attributes.model.creator")
        :library, # i18n-tasks-use t("activerecord.attributes.model.library")
        :name, # i18n-tasks-use t("activerecord.attributes.model.name")
        :caption, # i18n-tasks-use t("activerecord.attributes.model.caption")
        :notes, # i18n-tasks-use t("activerecord.attributes.model.notes")
        :license, # i18n-tasks-use t("activerecord.attributes.model.license")
        :sensitive, # i18n-tasks-use t("activerecord.attributes.model.sensitive")
        :indexable, # i18n-tasks-use t("activerecord.attributes.model.indexable")
        :ai_indexable, # i18n-tasks-use t("activerecord.attributes.model.ai_indexable")
        :entrypoint, # i18n-tasks-use t("activerecord.attributes.model.entrypoint")
        :entrypoint_fragment, # i18n-tasks-use t("activerecord.attributes.model.entrypoint_fragment")
        :q,
        :library,
        :tag,
        :organize,
        :missingtag,
        collection_ids: [],
        tag_list: [],
        links_attributes: [:id, :url, :text, :_destroy], # i18n-tasks-use t("activerecord.attributes.link.url")
        relationships_attributes: [:id, :predicate, :objekt_id, :_destroy] # i18n-tasks-use t("activerecord.attributes.model.relationships")
      )
      if allowed[:relationships_attributes]
        allowed[:relationships_attributes] = allowed[:relationships_attributes].to_h.map do |k, attrs|
          attrs[:objekt] = ModelPolicy::Scope.new(@user, Model).resolve.find_param(attrs.delete(:objekt_id)) if attrs[:objekt_id] && attrs[:id].nil?
          attrs
        end
      end
      allowed = resolve_collections(allowed)
      allowed = resolve_creator(allowed)
      allowed = resolve_library(allowed)
      allowed = resolve_file(allowed, :preview_file)
      allowed = resolve_file(allowed, :entrypoint)
      return allowed unless user_can_set_permissions?
      allowed.deep_merge(caber_relations_attributes(type: :model))
    end
  end
end
