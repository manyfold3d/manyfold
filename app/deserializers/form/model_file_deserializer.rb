module Form
  class ModelFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.require(:model_file).permit([
        :filename,
        :presupported,
        :notes,
        :caption,
        :y_up,
        :previewable,
        :presupported_version_id
      ])
    end
  end
end
