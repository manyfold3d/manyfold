module Form
  class UploadedModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.require(:model).permit(
        :name,
        :creator_id,
        :library,
        :license,
        :sensitive,
        :permission_preset,
        collection_ids: [],
        tag_list: [],
        file: [
          [:id, :name]
        ]
      )
      allowed = resolve_collections(allowed)
      resolve_creator(allowed)
    end
  end
end
