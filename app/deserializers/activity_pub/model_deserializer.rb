module ActivityPub
  class ModelDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      Model.create(
        name: @object.name,
        slug: @object.username,
        links_attributes: parse_link_attributes(@object),
        caption: @object.extensions&.dig("summary"),
        notes: @object.extensions&.dig("content"),
        # tags: parse from @object.extensions["attachment"]
        # creator: parse from @object.extensions["attributedTo"]
        # collection: parse from @object.extensions["context"]
        license: @object.extensions&.dig("spdx:license", "spdx:licenseId"),
        federails_actor: @object
      )
    end
  end
end
