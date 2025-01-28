module ActivityPub
  class ModelSerializer < ApplicationSerializer
    def serialize
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#"
        },
        summary: summary_html,
        "f3di:concreteType": "Model",
        attachment: @object.links.map { |it| {type: "Link", href: it.url} },
        sensitive: @object.sensitive
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
        @object.creator&.federails_actor&.followers_url,
        @object.collection&.federails_actor&.followers_url
      ].compact
    end

    private

    def public?
      ModelPolicy.new(nil, @object).show?
    end
  end
end
