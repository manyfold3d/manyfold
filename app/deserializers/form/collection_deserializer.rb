module Form
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params

      if user_can_set_permissions?
        @params.require(:collection).permit(
          :name,
          :creator_id,
          :collection_id,
          :caption,
          :notes,
          :indexable,
          :ai_indexable,
          :permission_preset,
          links_attributes: [:id, :url, :_destroy]
        ).deep_merge(caber_relations_attributes(type: :collection))
      else
        @params.require(:collection).permit(
          :name,
          :creator_id,
          :collection_id,
          :caption,
          :notes,
          :indexable,
          :ai_indexable,
          links_attributes: [:id, :url, :_destroy]
        )
      end
    end
  end
end
