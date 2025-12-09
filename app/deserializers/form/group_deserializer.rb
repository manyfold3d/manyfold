module Form
  class GroupDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      @params.expect(group: [:name])
    end
  end
end
