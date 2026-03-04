module Form
  class ModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:model).permit(
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
      return allowed unless user_can_set_permissions?
      allowed.deep_merge(caber_relations_attributes(type: :model))
    end
  end
end
