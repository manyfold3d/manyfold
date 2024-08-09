module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  included do
    acts_as_federails_actor username_field: :id, name_field: :name, profile_url_method: :url_for
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
    default_user = User.with_role(:administrator).first
    return if default_user.nil?
    Federails::Activity.create!(
      actor: default_user.actor,
      action: "Create",
      entity: actor,
      created_at: created_at
    )
  end

  def post_update_activity
    default_user = User.with_role(:administrator).first
    return if default_user.nil?
    Federails::Activity.create!(
      actor: default_user.actor,
      action: "Update",
      entity: actor,
      created_at: updated_at
    )
  end
end
