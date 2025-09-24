module ActivityPub
  class CreatorDeserializer < ApplicationDeserializer
    def create!
      options = deserialize.merge(
        federails_actor: @object
      )
      Creator.create!(options)
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
        indexable: (@object.extensions&.dig("indexable") == true) ? "yes" : "no",
        avatar_remote_url: (@object.extensions&.dig("icon", "type") == "Image") ? @object.extensions&.dig("icon", "url") : nil,
        banner_remote_url: (@object.extensions&.dig("image", "type") == "Image") ? @object.extensions&.dig("image", "url") : nil
      }.compact
    end
  end
end
