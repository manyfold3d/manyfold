module ActivityPub
  class CreatorPresenter < BasePresenter
    def present!
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

    def federate?
      # Currently unused
      public?
    end

    def to
      PUBLIC_COLLECTION if public?
    end

    def cc
      @object.federails_actor.followers_url
    end

    private

    def public?
      CreatorPolicy.new(nil, @object).show?
    end

    def summary_html
      return unless @object.caption || @object.notes
      "<section>#{"<header>#{@object.caption}</header>" if @object.caption}#{Kramdown::Document.new(@object.notes).to_html.rstrip if @object.notes}</section>"
    end
  end
end
