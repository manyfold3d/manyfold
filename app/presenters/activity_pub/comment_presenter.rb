module ActivityPub
  class CommentPresenter < BasePresenter
    def present!
      Federails::DataTransformer::Note.to_federation(
        @object,
        content: to_html,
        custom: {
          "context" => Rails.application.routes.url_helpers.url_for([@object.commentable, {only_path: false}]),
          "sensitive" => @object.sensitive,
          "tag" => hashtags
        }.merge(address_fields)
      )
    end

    def federate?
      @object.public?
    end

    def to
      PUBLIC_COLLECTION if @object.public?
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
      [
        Kramdown::Document.new(@object.comment).to_html,
        hashtags&.map { |t| %(<a href="#{t[:href]}" class="mention hashtag" rel="tag">#{t[:name]}</a>) }&.join(" ")
      ].compact.join("\n\n")
    end
  end
end
