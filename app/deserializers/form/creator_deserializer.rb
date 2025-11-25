module Form
  class CreatorDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
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
    end
  end
end
