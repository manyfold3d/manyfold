module ManyfoldApi::V0
  class GroupDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      members = []
      if @object["add_members"]
        members += @object["add_members"].filter_map do |it|
          {user: User.match!(identifier: it, invite: true)}
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end
      if @object["remove_members"] && @record
        members += @object["remove_members"].filter_map do |it|
          {id: @record.memberships.find_by(user: User.match!(identifier: it))&.id, _destroy: "1"}
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end
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
          add_members: {type: :array, items: {type: :string, example: "username / email / fediverse address"}},
          remove_members: {type: :array, items: {type: :string, example: "username / email / fediverse address"}}
        }
      }
    end
  end
end
