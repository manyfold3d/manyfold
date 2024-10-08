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
