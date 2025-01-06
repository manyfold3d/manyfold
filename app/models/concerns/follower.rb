module Follower
  extend ActiveSupport::Concern
  include FederailsCommon

  included do
    delegate :activities, to: :federails_actor
    delegate :following_follows, to: :federails_actor
  end

  def follows
    federails_actor.follows.map(&:user)
  end

  def follow(target)
    following_follows.create(target_actor: target.is_a?(Federails::Actor) ? target : target.federails_actor)
  end

  def unfollow(target)
    f = federails_actor.follows?(target.federails_actor)
    f&.destroy unless f == false
  end

  def following?(target)
    # follows? gives us the relationship or false if it doesn't exist,
    # so we turn that into a normal boolean
    tgt = target.is_a?(Federails::Actor) ? target : target.federails_actor
    federails_actor&.follows?(tgt)&.is_a?(Federails::Following)
  end
end
