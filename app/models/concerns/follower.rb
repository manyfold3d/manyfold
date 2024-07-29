module Follower
  extend ActiveSupport::Concern
  include Federails::User

  def follow(target)
    actor.following_follows.create(target_actor: target.actor)
  end

  def unfollow(target)
    f = actor.follows?(target.actor)
    f&.destroy unless f == false
  end

  def following?(target)
    # follows? gives us the relationship or false if it doesn't exist,
    # so we turn that into a normal boolean
    actor.follows?(target.actor) != false
  end
end
