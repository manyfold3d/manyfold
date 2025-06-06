module ActivityPub
  class CommentSerializer < ApplicationSerializer
    def serialize
      Federails::DataTransformer::Note.to_federation(
        @object,
        content: to_html,
        custom: {
          "@context" => [
            "https://purl.archive.org/miscellany",
            {
              f3di: "http://purl.org/f3di/ns#",
              Hashtag: "as:Hashtag"
            }
          ],
          "context" => Rails.application.routes.url_helpers.url_for([@object.commentable, {only_path: false}]),
          "sensitive" => @object.sensitive,
          "summary" => (@object.sensitive ? "Sensitive Content" : nil), # Adding a summary if sensitive, for Mastodon
          "tag" => hashtags,
          "f3di:compatibilityNote" => @object.system
        }.compact.merge(address_fields)
      )
    end

    def cc
      @object.commenter.federails_actor.followers_url
    end

    private

    def hashtags
      return nil unless @object.commentable.respond_to?(:tags)

      @object.commentable.tags.pluck(:name).map do |tag|
        {
          type: "Hashtag",
          name: "##{tag.tr(" ", "_").camelize}",
          href: Rails.application.routes.url_helpers.url_for([@object.commentable.class, {tag: tag}])
        }
      end
    end

    def to_html
      content = [Kramdown::Document.new(@object.comment, input: "GFM").to_html]
      tags = hashtags
      if !tags&.empty?
        content << "<p role=\"list\">#{tags.map { |t| %(<a role="listitem" href="#{t[:href]}" class="mention hashtag" rel="tag">#{t[:name]}</a>) }&.join(" ")}</p>"
      end
      content.join
    end
  end
end
