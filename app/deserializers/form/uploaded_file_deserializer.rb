module Form
  class UploadedFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.permit(
        file: [
          [:id, :name, :size, :type]
        ]
      )
    end
  end
end
