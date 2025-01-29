module ActivityPub
  class ModelDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      Model.create(
        name: @object.name,
        slug: @object.username,
        links_attributes: @object.extensions["attachment"]&.select { |it| it["type"] == "Link" }&.map { |it| {url: it["href"]} },
        caption: @object.extensions["summary"],
        notes: @object.extensions["content"],
        # tags: parse from @object.extensions["attachment"]
        # creator: parse from @object.extensions["attributedTo"]
        # collection: parse from @object.extensions["context"]
        license: @object.extensions&.dig("spdx:license", "spdx:licenseId"),
        federails_actor: @object
      )
    end
  end
end
