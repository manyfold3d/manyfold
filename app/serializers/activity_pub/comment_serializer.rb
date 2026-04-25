module ActivityPub
  class CommentSerializer < ApplicationSerializer
    def serialize
      {
        "@context" => Federails::Utils::Context.generate(additional: [
          "https://purl.archive.org/miscellany",
          {
            f3di: "http://purl.org/f3di/ns#",
            gts: "https://gotosocial.org/ns#",
            interactionPolicy: {
              "@id": "gts:interactionPolicy",
              "@type": "@id"
            },
            canQuote: {
              "@id": "gts:canQuote",
              "@type": "@id"
            },
            automaticApproval: {
              "@id": "gts:automaticApproval",
              "@type": "@id"
            },
            Hashtag: "as:Hashtag",
            sensitive: "as:sensitive"
          }
        ]),
        "id" => @object.federated_url,
        "type" => "Note",
        "attributedTo" => @object.federails_actor.federated_url,
        "published" => @object.created_at,
        "updated" => @object.updated_at,
        "context" => Rails.application.routes.url_helpers.url_for([@object.commentable, {only_path: false}]),
        "sensitive" => @object.sensitive,
        "summary" => (@object.sensitive ? "Sensitive Content" : nil), # Adding a summary if sensitive, for Mastodon
        "content" => content,
        "tag" => hashtags,
        "f3di:compatibilityNote" => @object.system,
        "inReplyTo" => in_reply_to,
        "url" => url,
        "likes" => likes,
        "interactionPolicy" => @object.system ? {
          "canQuote" => {
            "automaticApproval" => Fediverse::Collection::PUBLIC
          }
        } : nil
      }.compact.merge(address_fields)
    end

    def cc
      [
        @object.commentable&.federails_actor&.followers_url,
        @object.commenter&.federails_actor&.followers_url,
        (@object.commentable&.creator&.federails_actor&.followers_url if @object.commentable.respond_to?(:creator)),
        (@object.commentable&.collection&.federails_actor&.followers_url if @object.commentable.respond_to?(:collection)),
        (@object.commentable&.collections&.map { |c| c.federails_actor&.followers_url } if @object.commentable.respond_to?(:collections))
      ].flatten.compact
    end

    private

    def hashtags
      return nil unless @object.system && @object.commentable.respond_to?(:tags)

      @object.commentable.tags.pluck(:name).map do |tag|
        {
          type: "Hashtag",
          name: "##{tag.tr(" ", "_").camelize}",
          href: Rails.application.routes.url_helpers.url_for([@object.commentable.class, {tag: tag}])
        }
      end
    end

    def content
      Kramdown::Document.new(@object.comment, input: "GFM").to_html
    end

    def url
      anchor = @object.system ? nil : "comment-#{@object.to_param}"
      Rails.application.routes.url_helpers.url_for([@object.commentable, {only_path: false, anchor: anchor}.compact])
    end

    def in_reply_to
      # system notes aren't in reply to anything
      return nil if @object.system
      # Otherwise, find the system note or just use the actor URL if unavailable
      @object.commentable.comments.where(system: true).first&.federated_url || @object.commentable.federails_actor&.federated_url
    end

    def likes
      return nil unless @object.system
      {
        id: @object.commentable.federails_actor.federated_url + "#likes",
        type: "Collection",
        totalItems: @object.commentable.like_count
      }
    end
  end
end
