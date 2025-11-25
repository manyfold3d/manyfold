module Form
  class BaseDeserializer
    def initialize(params:, user:, record: nil)
      @params = params
      @user = user
      @record = record
    end

    def deserialize
      raise NotImplementedError
    end

    private

    def caber_relations_attributes(type: nil)
      @params.require(type).permit(
        caber_relations_attributes: [:id, :subject_type, :subject_id, :permission, :_destroy]
      )
    end
  end
end
