module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  TIMEOUT = 15

  included do
    delegate :following_followers, to: :federails_actor
    after_commit :followable_post_creation_activity, on: :create
    after_commit :followable_post_update_activity, on: :update

    after_followed :auto_accept
  end

  def followers
    federails_actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    federails_actor.followers.include? follower.federails_actor
  end

  private

  def followable_post_creation_activity
    followable_post_activity("Create")
  end

  def followable_post_update_activity
    followable_post_activity("Update") unless Federails::Activity.exists?(entity: federails_actor, created_at: TIMEOUT.minutes.ago..)
  end

  def followable_post_activity(action)
    user = permitted_users.with_permission("own").first || SiteSettings.default_user
    return if user.nil?
    Federails::Activity.create!(
      actor: user.federails_actor,
      action: action,
      entity: federails_actor,
      created_at: updated_at
    )
  end

  def auto_accept
    federails_actor.following_followers.where(status: "pending").find_each { |it| it.accept! }
  end
end
