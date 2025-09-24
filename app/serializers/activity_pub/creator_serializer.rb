module ActivityPub
  class CreatorSerializer < ApplicationSerializer
    def serialize
      raise ActiveRecord::RecordNotFound unless federate? # Temporary guard against publishing non-public Federails::ActorEntity objects
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#",
          toot: "http://joinmastodon.org/ns#",
          indexable: "toot:indexable",
          discoverable: "toot:discoverable",
          attributionDomains: {
            "@id": "toot:attributionDomains",
            "@type": "@id"
          }
        },
        summary: @object.caption,
        content: @object.notes,
        attributionDomains: [
          [Rails.application.default_url_options[:host], Rails.application.default_url_options[:port]].compact.join(":")
        ],
        "f3di:concreteType": "Creator",
        indexable: @object.indexable?,
        discoverable: @object.indexable?,
        attachment: @object.links.map { |it| {type: "Link", href: it.url} },
        icon: @object.avatar ? {
          type: "Image",
          mediaType: @object.avatar.mime_type,
          url: Rails.application.routes.url_helpers.avatar_creator_url(@object)
        } : nil,
        image: @object.banner ? {
          type: "Image",
          mediaType: @object.banner.mime_type,
          url: Rails.application.routes.url_helpers.banner_creator_url(@object)
        } : nil
      }.merge(address_fields)
    end

    def cc
      @object.federails_actor.followers_url
    end
  end
end
