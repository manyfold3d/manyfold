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
      allowed[:collections] = CollectionPolicy::Scope.new(@user, Collection).resolve.where(public_id: allowed.delete(:collection_ids))
      allowed
    end
  end
end
