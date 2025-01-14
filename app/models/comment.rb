require "federails/data_transformer/note"

class Comment < ApplicationRecord
  include PublicIDable

  belongs_to :commenter, polymorphic: true, optional: true
  belongs_to :commentable, polymorphic: true

  include Federails::DataEntity
  acts_as_federails_data handles: "Note", actor_entity_method: :commenter, url_param: :public_id, should_federate_method: :public?

  def to_activitypub_object
    # Comments become Notes in ActvityPub
    Federails::DataTransformer::Note.to_federation self, content: to_html,
      custom: {
        "context" => Rails.application.routes.url_helpers.url_for([commentable, only_path: false]),
        "sensitive" => sensitive,
        "tag" => activitypub_tags
      }.merge(address_options)
  end

  def public?
    Pundit::PolicyFinder.new(commenter.class).policy.new(nil, commenter).show? &&
      Pundit::PolicyFinder.new(commentable.class).policy.new(nil, commentable).show?
  end

  private

  def activitypub_tags
    return nil unless commentable.respond_to?(:tags)
    commentable.tags.pluck(:name).map do |tag|
      {
        type: "Hashtag",
        name: "##{tag.tr(" ", "_").camelize}",
        href: Rails.application.routes.url_helpers.url_for([commentable.class, tag: tag])
      }
    end
  end

  def to_html
    [
      Kramdown::Document.new(comment).to_html,
      activitypub_tags&.map { |t| %(<a href="#{t[:href]}" class="mention hashtag" rel="tag">#{t[:name]}</a>) }&.join(" ")
    ].compact.join("\n\n")
  end

  def address_options
    public? ?
      {
        "to" => ["https://www.w3.org/ns/activitystreams#Public"],
        "cc" => [commenter.federails_actor.followers_url]
      }
    : {}
  end
end
