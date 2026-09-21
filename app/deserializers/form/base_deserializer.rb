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

    def caber_relations_attributes(type:)
      @params.require(type).permit(
        :permission_preset,
        caber_relations_attributes: [:id, :subject_type, :subject_id, :permission, :_destroy]
      )
    end

    def resolve_creator(params)
      return params unless params[:creator_id]

      params[:creator] = CreatorPolicy::UpdateScope.new(@user, Creator).resolve.find_by(id: params.delete(:creator_id))
      params
    rescue ActiveRecord::RecordNotFound
      params
    end

    def user_can_set_permissions?
      @user.is_moderator? || (@record && @user&.owns?(@record))
    end
  end
end
