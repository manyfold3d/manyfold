module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  TIMEOUT = 5

  included do
    delegate :following_followers, to: :actor
    after_commit :post_creation_activity, on: :create
    after_commit :post_update_activity, on: :update

    after_followed :auto_accept
  end

  def followers
    actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end

  private

  def post_creation_activity
    user = permitted_users.with_permission("own").first || SiteSettings.default_user
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
    return if actor&.activities_as_entity&.where(created_at: TIMEOUT.minutes.ago..)&.count&.> 0
    user = permitted_users.with_permission("own").first || SiteSettings.default_user
    return if user.nil?
    Federails::Activity.create!(
      actor: user.actor,
      action: "Update",
      entity: actor,
      created_at: updated_at
    )
  end

  def auto_accept
    actor.following_followers.where(status: "pending").find_each { |x| x.accept! }
  end
end
