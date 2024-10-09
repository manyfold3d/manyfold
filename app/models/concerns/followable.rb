module Followable
  extend ActiveSupport::Concern
  include FederailsCommon

  TIMEOUT = 5

  included do
    delegate :following_followers, to: :actor

    after_followed :auto_accept
  end

  def followers
    actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end

  private

  def auto_accept
    actor.following_followers.where(status: "pending").find_each { |x| x.accept! }
  end
end
