module ActivityPub
  class ModelDeserializer < ApplicationDeserializer
    def create!
      options = deserialize.merge(
        federails_actor: @object,
        library: Library.first, # TODO: This is not ideal
        path: SecureRandom.uuid
      )
      Model.create!(options)
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
        tag_list: parse_tags(@object),
        license: @object.extensions&.dig("spdx:license", "spdx:licenseId"),
        indexable: (@object.extensions&.dig("indexable") == true) ? "yes" : "no"
      }
    end

    def parse_tags(object)
      tags = object.extensions&.dig("tag") || []
      tags.select { |it| it["type"] == "Hashtag" }&.map { |it| it["name"].delete_prefix("#") }
    end
  end
end
