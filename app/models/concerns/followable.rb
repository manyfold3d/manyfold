module Followable
  extend ActiveSupport::Concern
  include Federails::User

  included do
    delegate :following_followers, to: :actor
  end

  def followers
    actor.followers.map(&:user)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end
end
