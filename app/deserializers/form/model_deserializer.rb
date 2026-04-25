module Form
  class ModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:model).permit(
        :preview_file_id, # i18n-tasks-use t("activerecord.attributes.model.preview_file")
        :creator_id, # i18n-tasks-use t("activerecord.attributes.model.creator_id")
        :library_id, # i18n-tasks-use t("activerecord.attributes.model.library_id")
        :name, # i18n-tasks-use t("activerecord.attributes.model.name")
        :caption, # i18n-tasks-use t("activerecord.attributes.model.caption")
        :notes, # i18n-tasks-use t("activerecord.attributes.model.notes")
        :license, # i18n-tasks-use t("activerecord.attributes.model.license")
        :sensitive, # i18n-tasks-use t("activerecord.attributes.model.sensitive")
        :indexable, # i18n-tasks-use t("activerecord.attributes.model.indexable")
        :ai_indexable, # i18n-tasks-use t("activerecord.attributes.model.ai_indexable")
        :q,
        :library,
        :creator,
        :tag,
        :organize,
        :missingtag,
        collection_ids: [],
        tag_list: [],
        links_attributes: [:id, :url, :_destroy] # i18n-tasks-use t("activerecord.attributes.link.url")
      )
      allowed[:collections] = CollectionPolicy::Scope.new(@user, Collection).resolve.where(public_id: allowed.delete(:collection_ids))
      return allowed unless user_can_set_permissions?
      allowed.deep_merge(caber_relations_attributes(type: :model))
    end
  end
end
