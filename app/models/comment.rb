class Comment < ApplicationRecord
  include PublicIDable

  belongs_to :commenter, polymorphic: true
  belongs_to :commentable, polymorphic: true

  after_create :post_create_activity
  after_update :post_update_activity
  after_destroy :post_destroy_activity

  def federated_url
    return nil unless public?
    Rails.application.routes.url_helpers.url_for([commentable, self, {only_path: false}])
  end

  def to_activitypub_object
    # Comments become Notes in ActvityPub world
    {
      id: federated_url,
      type: "Note",
      content: Kramdown::Document.new(comment).to_html,
      context: Rails.application.routes.url_helpers.url_for([commentable, only_path: false]),
      published: created_at&.iso8601,
      attributedTo: (commenter&.actor&.respond_to?(:federated_url) ? commenter.actor.federated_url : nil),
      to: ["https://www.w3.org/ns/activitystreams#Public"],
      cc: [commenter.actor.followers_url]
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
