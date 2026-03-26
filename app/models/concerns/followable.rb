module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  included do
    delegate :following_followers, to: :federails_actor
    after_followed :auto_accept
  end

  def followers
    federails_actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    federails_actor.followers.include? follower.federails_actor
  end

  private

  def auto_accept(follow)
    return unless federails_actor.local?
    follow.accept!
  end
end
