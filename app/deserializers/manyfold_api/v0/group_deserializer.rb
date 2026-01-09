module ManyfoldApi::V0
  class GroupDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      members = []
      members += @object["add_members"].map { |it| {user: User.find_by(username: it)} } if @object["add_members"]
      members += @object["remove_members"].map { |it| {id: @record.memberships.find_by(user: User.find_by(username: it))&.id, _destroy: "1"} } if @object["remove_members"] && @record
      memberships_attributes = (0...members.count).map(&:to_s).zip(members).to_h
      {
        name: @object["name"],
        description: @object["description"],
        memberships_attributes: memberships_attributes
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Patrons"},
          description: {type: :string, example: "My subscribers"},
          add_members: {type: :array, items: {type: :string, example: "username"}},
          remove_members: {type: :array, items: {type: :string, example: "username"}}
        }
      }
    end
  end
end
