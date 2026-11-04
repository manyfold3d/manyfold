module Form
  class UploadedFileDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.permit(
        model: {
          file: [
            [
              :id,
              :name,
              relationships_attributes: [:predicate, :objekt_id]
            ]
          ]
        }
      )
      if allowed.dig(:model, :file)
        allowed[:model][:file] = allowed.dig(:model, :file)&.transform_values do |file_params|
          if file_params[:relationships_attributes]
            file_params[:relationships_attributes] = file_params[:relationships_attributes]&.transform_values do |relationship|
              relationship[:objekt] = @record.model_files.find_param(relationship.delete(:objekt_id)) if relationship[:objekt_id]
              relationship
            end
          end
          file_params
        end
      end
      allowed
    end
  end
end
