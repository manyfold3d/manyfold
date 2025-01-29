module ActivityPub
  class CreatorDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      Creator.create(
        name: @object.name,
        slug: @object.username,
        links_attributes: parse_link_attributes(@object),
        caption: @object.extensions&.dig("summary"),
        notes: @object.extensions&.dig("content"),
        federails_actor: @object
      )
    end
  end
end
