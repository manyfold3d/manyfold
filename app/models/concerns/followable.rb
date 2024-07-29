module Followable
  extend ActiveSupport::Concern
  include Federails::User

  def followers
    actor.followers.map(&:user)
  end

  def followed_by?(follower)
    actor.followers.include? follower.actor
  end
end
