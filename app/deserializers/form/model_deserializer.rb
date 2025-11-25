module Form
  class ModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params

      if user_can_set_permissions?
        @params.require(:model).permit(
          :preview_file_id,
          :creator_id,
          :library_id,
          :name,
          :caption,
          :notes,
          :license,
          :sensitive,
          :indexable,
          :ai_indexable,
          :collection_id,
          :q,
          :library,
          :creator,
          :tag,
          :organize,
          :missingtag,
          :permission_preset,
          tag_list: [],
          links_attributes: [:id, :url, :_destroy]
        ).deep_merge(caber_relations_attributes(type: :model))
      else
        @params.require(:model).permit(
          :preview_file_id,
          :creator_id,
          :library_id,
          :name,
          :caption,
          :notes,
          :license,
          :sensitive,
          :indexable,
          :ai_indexable,
          :collection_id,
          :q,
          :library,
          :creator,
          :tag,
          :organize,
          :missingtag,
          tag_list: [],
          links_attributes: [:id, :url, :_destroy]
        )
      end
    end
  end
end
