module ActivityPub
  class ModelSerializer < ApplicationSerializer
    def serialize
      raise ActiveRecord::RecordNotFound unless federate? # Temporary guard against publishing non-public Federails::ActorEntity objects
      {
        "@context": [
          "https://purl.archive.org/miscellany",
          {
            spdx: "http://spdx.org/rdf/terms#",
            f3di: "http://purl.org/f3di/ns#",
            toot: "http://joinmastodon.org/ns#",
            Hashtag: "as:Hashtag",
            sensitive: "as:sensitive",
            indexable: "toot:indexable",
            discoverable: "toot:discoverable"
          }
        ],
        summary: @object.caption,
        content: @object.notes,
        "f3di:concreteType": "3DModel",
        attachment: @object.links.map { |it| {type: "Link", href: it.url} },
        sensitive: @object.sensitive,
        indexable: @object.indexable?,
        discoverable: @object.indexable?,
        tag: hashtags,
        attributedTo: short_creator(@object.creator),
        context: short_collection(@object.collection),
        "spdx:license": license,
        preview: oembed_to_preview(OEmbed::ModelSerializer.new(@object, maxwidth: "100%", maxheight: "100%").serialize)
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

    def license
      return if @object.license.blank?
      {
        "@id": @object.license.starts_with?("LicenseRef-") ?
          nil :
          "http://spdx.org/licenses/#{@object.license}",
        "spdx:licenseId": @object.license
      }.compact
    end

    def hashtags
      @object.tags.pluck(:name).map do |tag|
        {
          type: "Hashtag",
          name: tag,
          href: Rails.application.routes.url_helpers.models_url(tag: tag)
        }
      end
    end
  end
end
