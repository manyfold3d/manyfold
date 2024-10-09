class Comment < ApplicationRecord
  include PublicIDable

  belongs_to :commenter, polymorphic: true
  belongs_to :commentable, polymorphic: true

  after_create :post_create_activity
  after_update :post_update_activity
  after_destroy :post_destroy_activity

  def federated_url
    Rails.application.routes.url_helpers.url_for([commentable, self, {only_path: false}])
  end

  def to_activitypub_object(include_context: false)
    # Comments become Notes in ActvityPub world
    Jbuilder.encode do |json|
      json.set! "@context", "https://www.w3.org/ns/activitystreams" if include_context
      json.id federated_url
      json.type "Note"
      json.content Kramdown::Document.new(comment).to_html
      json.context Rails.application.routes.url_helpers.url_for([commentable, only_path: false])
      json.published created_at&.iso8601
      if commenter&.actor&.respond_to? :federated_url
        json.attributedTo commenter.actor.federated_url
      end
      json.to ["https://www.w3.org/ns/activitystreams#Public"]
      json.cc [commenter.actor.followers_url]
    end
  end

  private

  def post_create_activity
    post_activity "Create"
  end

  def post_update_activity
    post_activity "Update"
  end

  def post_activity(action)
    Federails::Activity.create!(
      actor: commenter.actor,
      action: action,
      entity: self
    )
  end
end
