module Followable
  extend ActiveSupport::Concern
  include FedipubCommon

  included do
    delegate :following_followers, to: :fedipub_actor
    after_followed :auto_accept
  end

  def followers
    fedipub_actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    fedipub_actor.followers.include? follower.fedipub_actor
  end

  private

  def auto_accept(follow)
    return unless fedipub_actor.local?
    follow.accept!
  end
end
