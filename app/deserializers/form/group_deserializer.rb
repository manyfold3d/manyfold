module Form
  class GroupDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.require(:group).permit(
        :name, # i18n-tasks-use t("activerecord.attributes.group.name")
        :description, # i18n-tasks-use t("activerecord.attributes.group.description")
        memberships_attributes: [:id, :user_id, :_destroy] # i18n-tasks-use t("activerecord.attributes.group.memberships")
      )
    end
  end
end
