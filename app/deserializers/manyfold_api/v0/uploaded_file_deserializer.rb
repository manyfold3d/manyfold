module ManyfoldApi::V0
  class UploadedFileDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        model: {
          file: @object.dig("files")&.each_with_index.to_h.invert
        }
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          files: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: {type: :string, description: "The ID of a completed upload, obtained from the upload endpoints", example: "http://example.com/uploads/abc123456def"},
                name: {type: :string, example: "model.stl"}
              },
              required: [:id, :name, :type, :size]
            }
          }
        },
        required: [:files]
      }
    end
  end
end
