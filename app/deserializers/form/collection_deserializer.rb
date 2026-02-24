module Form
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:collection).permit(
        :name,
        :creator_id,
        :collection_id,
        :caption,
        :notes,
        :indexable,
        :ai_indexable,
        links_attributes: [:id, :url, :_destroy]
      )
      return allowed unless user_can_set_permissions?
      allowed.deep_merge(caber_relations_attributes(type: :collection))
    end
  end
end
