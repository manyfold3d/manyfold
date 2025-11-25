module Form
  class CreatorDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      if user_can_set_permissions?
        @params.require(:creator).permit(
          :name,
          :slug,
          :caption,
          :notes,
          :indexable,
          :ai_indexable,
          :avatar,
          :remove_avatar,
          :banner,
          :remove_banner,
          :permission_preset,
          links_attributes: [:id, :url, :_destroy]
        ).deep_merge(caber_relations_attributes(type: :creator))
      else
        @params.require(:creator).permit(
          :name,
          :slug,
          :caption,
          :notes,
          :indexable,
          :ai_indexable,
          :avatar,
          :remove_avatar,
          :banner,
          :remove_banner,
          links_attributes: [:id, :url, :_destroy]
        )
      end
    end
  end
end
