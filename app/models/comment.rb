class Comment < ApplicationRecord
  include PublicIDable

  belongs_to :commenter, polymorphic: true
  belongs_to :commentable, polymorphic: true

  after_create :post_create_activity
  after_update :post_update_activity

  def federated_url
    return nil unless public?
    Rails.application.routes.url_helpers.url_for([commentable, self, {only_path: false}])
  end

  def to_activitypub_object
    # Build tag structure
    tags = commentable.respond_to?(:tags) ?
      commentable.tags.pluck(:name).map do |tag|
        {
          type: "Hashtag",
          name: "##{tag.tr(" ", "_").camelize}",
          href: Rails.application.routes.url_helpers.url_for([commentable.class, tag: tag])
        }
      end
    : nil
    tag_html = tags&.map { |t| %(<a href="#{t[:href]}" class="mention hashtag" rel="tag">#{t[:name]}</a>) }&.join(" ")
    # Comments become Notes in ActvityPub world
    {
      id: federated_url,
      type: "Note",
      content: [
        Kramdown::Document.new(comment).to_html,
        tag_html
      ].compact.join("\n\n"),
      context: Rails.application.routes.url_helpers.url_for([commentable, only_path: false]),
      published: created_at&.iso8601,
      attributedTo: (commenter&.actor&.respond_to?(:federated_url) ? commenter.actor.federated_url : nil),
      sensitive: sensitive,
      to: ["https://www.w3.org/ns/activitystreams#Public"],
      cc: [commenter.actor.followers_url],
      tag: tags
    }.compact
  end

  def public?
    Pundit::PolicyFinder.new(commenter.class).policy.new(nil, commenter).show? &&
      Pundit::PolicyFinder.new(commentable.class).policy.new(nil, commentable).show?
  end

  private

  def post_create_activity
    post_activity "Create"
  end

  def post_update_activity
    post_activity "Update"
  end

  def post_activity(action)
    if public?
      Federails::Activity.create!(
        actor: commenter.actor,
        action: action,
        entity: self
      )
    end
  end
end
