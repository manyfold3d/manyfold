module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  included do
    delegate :following_followers, to: :actor

    after_create :post_creation_activity
  end

  def followers
    actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end

  private

  def post_creation_activity
    default_user = User.with_role(:administrator).first
    return if default_user.nil?
    Federails::Activity.create!(
      actor: default_user.actor,
      action: "Create",
      entity: actor,
      created_at: created_at
    )
  end
end
