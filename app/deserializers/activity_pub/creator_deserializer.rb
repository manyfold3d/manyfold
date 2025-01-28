module ActivityPub
  class CreatorDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      matches = @object.extensions["summary"].match(/<section><header>(.+)<\/header><p>(.+)<\/p><\/section>/)
      create(
        name: @object.name,
        slug: @object.username,
        links_attributes: @object.extensions["attachment"]&.select { |it| it["type"] == "Link" }&.map { |it| {url: it["href"]} },
        caption: matches ? matches[1] : nil,
        notes: matches ? matches[2] : nil,
        federails_actor: @object
      )
    end
  end
end
