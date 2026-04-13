module Form
  class CreatorDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:creator).permit(
        :name, # i18n-tasks-use t("activerecord.attributes.creator.name")
        :slug, # i18n-tasks-use t("activerecord.attributes.creator.slug")
        :caption, # i18n-tasks-use t("activerecord.attributes.creator.caption")
        :notes, # i18n-tasks-use t("activerecord.attributes.creator.notes")
        :indexable, # i18n-tasks-use t("activerecord.attributes.creator.indexable")
        :ai_indexable, # i18n-tasks-use t("activerecord.attributes.creator.ai_indexable")
        :avatar, # i18n-tasks-use t("activerecord.attributes.creator.avatar")
        :remove_avatar,
        :banner, # i18n-tasks-use t("activerecord.attributes.creator.banner")
        :remove_banner,
        links_attributes: [:id, :url, :_destroy] # i18n-tasks-use t("activerecord.attributes.creator.links")
      )
      return allowed unless user_can_set_permissions?
      allowed.deep_merge(caber_relations_attributes(type: :creator))
    end
  end
end
