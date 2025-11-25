module Form
  class BaseDeserializer
    def initialize(params:, user:)
      @params = params
      @user = user
    end

    def deserialize
      raise NotImplementedError
    end

    private

    def caber_relations_params(type: nil)
      @params.require(type).permit(
        caber_relations_attributes: [:id, :subject_type, :subject_id, :permission, :_destroy]
      )
    end
  end
end
