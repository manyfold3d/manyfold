module Form
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
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
      ).deep_merge(caber_relations_params(type: :collection))
    end
  end
end
