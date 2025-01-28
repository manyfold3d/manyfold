module ActivityPub
  class CollectionDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      Collection.create(
        name: @object.name,
        slug: @object.username,
        links_attributes: @object.extensions["attachment"]&.select { |it| it["type"] == "Link" }&.map { |it| {url: it["href"]} },
        caption: @object.extensions["summary"],
        notes: @object.extensions["content"],
        # collection: parse from @object.extensions["context"]
        federails_actor: @object
      )
    end
  end
end
