module Form
  class GroupDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.require(:group).permit(
        :name,
        memberships_attributes: [:id, :user_id, :_destroy]
      )
    end
  end
end
