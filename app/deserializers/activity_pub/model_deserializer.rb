module ActivityPub
  class ModelDeserializer < ApplicationDeserializer
    def deserialize
      raise ArgumentError unless @object.is_a?(Federails::Actor)
      Model.create!(
        library: Library.first, # TODO: This is not ideal
        path: SecureRandom.uuid,
        name: @object.name,
        slug: @object.username,
        links_attributes: parse_link_attributes(@object),
        caption: @object.extensions&.dig("summary"),
        notes: @object.extensions&.dig("content"),
        tag_list: parse_tags(@object),
        # creator: parse from @object.extensions["attributedTo"]
        # collection: parse from @object.extensions["context"]
        license: @object.extensions&.dig("spdx:license", "spdx:licenseId"),
        federails_actor: @object
      )
    end

    private

    def parse_tags(object)
      tags = object.extensions&.dig("tag") || []
      tags.select { |it| it["type"] == "Hashtag" }&.map { |it| it["name"].delete_prefix("#").underscore.humanize }
    end
  end
end
