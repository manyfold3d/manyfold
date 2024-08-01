module Followable
  extend ActiveSupport::Concern
  include Federails::Entity

  included do
    delegate :following_followers, to: :actor
  end

  def followers
    actor.followers.map(&:entity)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end
end
