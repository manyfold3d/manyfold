module ActivityPub
  class CollectionSerializer < ApplicationSerializer
    def serialize
      raise ActiveRecord::RecordNotFound unless federate? # Temporary guard against publishing non-public Federails::ActorEntity objects
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#"
        },
        summary: summary_html,
        "f3di:concreteType": "Collection",
        attachment: @object.links.map { |it| {type: "Link", href: it.url} }
      }.merge(address_fields)
    end

    def cc
      [
        @object.federails_actor.followers_url,
        @object.collection&.federails_actor&.followers_url
      ].compact
    end
  end
end
