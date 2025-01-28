module ActivityPub
  class ModelSerializer < ApplicationSerializer
    def serialize
      raise ActiveRecord::RecordNotFound unless federate? # Temporary guard against publishing non-public Federails::ActorEntity objects
      {
        "@context": {
          f3di: "http://purl.org/f3di/ns#",
          Hashtag: "as:Hashtag"
        },
        summary: @object.caption,
        content: @object.notes,
        "f3di:concreteType": "Model",
        attachment: @object.links.map { |it| {type: "Link", href: it.url} },
        sensitive: @object.sensitive,
        tag: hashtags
      }.compact.merge(address_fields)
    end

    def cc
      [
        @object.federails_actor.followers_url,
        @object.creator&.federails_actor&.followers_url,
        @object.collection&.federails_actor&.followers_url
      ].compact
    end

    private

    def hashtags
      @object.tags.pluck(:name).map do |tag|
        {
          type: "Hashtag",
          name: "##{tag.tr(" ", "_").camelize}",
          href: Rails.application.routes.url_helpers.models_url(tag: tag)
        }
      end
    end
  end
end
