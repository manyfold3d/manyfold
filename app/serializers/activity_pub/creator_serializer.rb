module ActivityPub
  class CreatorSerializer < ApplicationSerializer
    def serialize
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#",
          toot: "http://joinmastodon.org/ns#",
          attributionDomains: {
            "@id": "toot:attributionDomains",
            "@type": "@id"
          }
        },
        summary: summary_html,
        attributionDomains: [
          [Rails.application.default_url_options[:host], Rails.application.default_url_options[:port]].compact.join(":")
        ],
        "f3di:concreteType": "Creator",
        attachment: @object.links.map { |it| {type: "Link", href: it.url} }
      }.merge(address_fields)
    end

    def cc
      @object.federails_actor.followers_url
    end
  end
end
