module Form
  class UploadedFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.permit(
        model: {
          file: [
            [:id, :name]
          ]
        }
      )
    end
  end
end
