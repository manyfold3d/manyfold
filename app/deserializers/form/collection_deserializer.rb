module Form
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:collection).permit(
        :name, # i18n-tasks-use t("activerecord.attributes.collection.name")
        :creator_id, # i18n-tasks-use t("activerecord.attributes.collection.creator")
        :collection_id, # i18n-tasks-use t("activerecord.attributes.collection.collection")
        :caption, # i18n-tasks-use t("activerecord.attributes.collection.caption")
        :notes, # i18n-tasks-use t("activerecord.attributes.collection.notes")
        :indexable, # i18n-tasks-use t("activerecord.attributes.collection.indexable")
        :ai_indexable, # i18n-tasks-use t("activerecord.attributes.collection.ai_indexable")
        links_attributes: [:id, :url, :_destroy]
      )
      return allowed unless user_can_set_permissions?
      allowed.deep_merge(caber_relations_attributes(type: :collection))
    end
  end
end
