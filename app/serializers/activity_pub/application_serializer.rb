module ActivityPub
  class ApplicationSerializer < BaseSerializer
    def federate?
      @object.public?
    end

    def to
      PUBLIC_COLLECTION if @object.public?
    end

    private

    def short_creator(creator)
      return nil unless creator
      {
        "@id": creator.federails_actor.federated_url,
        type: "Person",
        name: creator.name,
        url: creator.federails_actor.profile_url,
        "f3di:concreteType": "Creator"
      }
    end

    def short_collection(collection)
      return nil unless collection
      {
        "@id": collection.federails_actor.federated_url,
        type: "Group",
        name: collection.name,
        url: collection.federails_actor.profile_url,
        "f3di:concreteType": "Collection"
      }
    end

    def oembed_to_preview(oembed_data)
      data = case oembed_data[:type]
      when "photo"
        {
          type: "Image",
          url: oembed_data[:url],
          mediaType: oembed_data[:mediaType]
        }
      when "rich"
        {
          type: "Document",
          content: oembed_data[:html],
          mediaType: "text/html"
        }
      when "video"
        {
          type: "Video",
          url: oembed_data[:url],
          mediaType: oembed_data[:mediaType]
        }
      end
      data&.merge({
        name: oembed_data[:name],
        summary: oembed_data[:summary]
      })&.compact
    end
  end
end
