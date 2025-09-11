module ActivityPub
  class CollectionSerializer < ApplicationSerializer
    def serialize
      raise ActiveRecord::RecordNotFound unless federate? # Temporary guard against publishing non-public Federails::ActorEntity objects
      {
        "@context": [
          {
            f3di: "http://purl.org/f3di/ns#",
            toot: "http://joinmastodon.org/ns#",
            indexable: "toot:indexable",
            discoverable: "toot:discoverable"
          }
        ],
        summary: @object.caption,
        content: @object.notes,
        "f3di:concreteType": "Collection",
        indexable: @object.indexable?,
        discoverable: @object.indexable?,
        attachment: @object.links.map { |it| {type: "Link", href: it.url} },
        attributedTo: short_creator(@object.creator),
        context: short_collection(@object.collection),
        preview: oembed_to_preview(OEmbed::CollectionSerializer.new(@object, maxwidth: "100%", maxheight: "100%").serialize)
      }.merge(address_fields)
    end

    def cc
      [
        @object.federails_actor.followers_url,
        @object.creator&.federails_actor&.followers_url,
        @object.collection&.federails_actor&.followers_url
      ].compact
    end
  end
end
