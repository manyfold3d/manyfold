module ActivityPub
  class CollectionDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      Collection.create(
        name: @object.name,
        slug: @object.username,
        links_attributes: parse_link_attributes(@object),
        caption: @object.extensions&.dig("summary"),
        notes: @object.extensions&.dig("content"),
        # collection: parse from @object.extensions["context"]
        federails_actor: @object
      )
    end
  end
end
