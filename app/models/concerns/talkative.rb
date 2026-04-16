module Talkative
  extend ActiveSupport::Concern

  TIMEOUT = Rails.env.development? ? 1 : 15

  included do
    after_commit :followable_post_creation_activity, on: :create
    after_commit :followable_post_update_activity, on: :update
  end

  def owning_actor
    return nil unless caber_ready?
    owners.first&.federails_actor
  end

  private

  def recently_posted?
    return false unless DatabaseDetector.table_ready? "federails_activities"
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
