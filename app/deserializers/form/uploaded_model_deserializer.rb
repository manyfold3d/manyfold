module Form
  class UploadedModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.permit(
        :creator_id,
        :collection_id,
        :library,
        :license,
        :sensitive,
        add_tags: [],
        file: [
          [:id, :name, :size, :type]
        ]
      )
    end
  end
end
