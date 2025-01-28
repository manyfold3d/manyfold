module ActivityPub
  class CollectionSerializer < ApplicationSerializer
    def serialize
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#"
        },
        summary: summary_html,
        "f3di:concreteType": "Collection",
        attachment: @object.links.map { |it| {type: "Link", href: it.url} }
      }.merge(address_fields)
    end

    def federate?
      # Currently unused
      public?
    end

    def to
      PUBLIC_COLLECTION if public?
    end

    def cc
      [
        @object.federails_actor.followers_url,
        @object.collection&.federails_actor&.followers_url
      ].compact
    end
  end
end
