module ActivityPub
  class CollectionDeserializer < ApplicationDeserializer
    def create!
      options = deserialize.merge(
        federails_actor: @object
      )
      Collection.create!(options)
    end

    private

    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      {
        name: @object.name,
        slug: @object.username,
        links: [], # Overwrite existing links
        links_attributes: parse_link_attributes(@object),
        caption: @object.extensions&.dig("summary"),
        notes: @object.extensions&.dig("content"),
        indexable: (@object.extensions&.dig("indexable") == true) ? "yes" : "no"
      }
    end
  end
end
