module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  TIMEOUT = Rails.env.development? ? 1 : 15

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

  def owning_actor
    return nil unless caber_ready?
    user = permitted_users.with_permission("own").first || SiteSettings.default_user
    user&.federails_actor
  end

  private

  def recently_posted?
    return false unless ActiveRecord::Base.connection.data_source_exists? "federails_activities"
    Federails::Activity.exists?(action: ["Create", "Update"], entity: federails_actor, created_at: TIMEOUT.minutes.ago..)
  end

  def followable_post_creation_activity
    followable_post_activity("Create")
  end

  def followable_post_update_activity
    followable_post_activity("Update") unless recently_posted?
  end

  def followable_post_activity(action)
    return unless owning_actor
    Federails::Activity.create!(
      actor: owning_actor,
      action: action,
      entity: federails_actor,
      created_at: updated_at
    )
  end

  def auto_accept(follow)
    return unless federails_actor.local?
    follow.accept!
  end
end
