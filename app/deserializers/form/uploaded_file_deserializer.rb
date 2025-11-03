module Form
  class UploadedFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.require(:model).permit(
        file: [
          [:id, :name]
        ]
      )
    end
  end
end
