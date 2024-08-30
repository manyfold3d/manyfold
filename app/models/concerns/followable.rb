module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  TIMEOUT = 5

  included do
    delegate :following_followers, to: :actor
    after_create :post_creation_activity
    after_update :post_update_activity
  end

  def followers
    actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end

  private

  def post_creation_activity
    user = permitted_users.with_permission("owner").first || SiteSettings.default_user
    return if user.nil?
    user.create_actor_if_missing
    Federails::Activity.create!(
      actor: user.actor,
      action: "Create",
      entity: actor,
      created_at: created_at
    )
  end

  def post_update_activity
    return if actor.activities_as_entity.where(created_at: TIMEOUT.minutes.ago..).count > 0
    user = permitted_users.with_permission("owner").first || SiteSettings.default_user
    return if user.nil?
    Federails::Activity.create!(
      actor: user.actor,
      action: "Update",
      entity: actor,
      created_at: updated_at
    )
  end
end
