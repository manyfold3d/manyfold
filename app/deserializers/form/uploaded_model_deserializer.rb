module Form
  class UploadedModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.require(:model).permit(
        :name,
        :creator_id,
        :collection_id,
        :library,
        :license,
        :sensitive,
        :permission_preset,
        tag_list: [],
        file: [
          [:id, :name]
        ]
      )
    end
  end
end
