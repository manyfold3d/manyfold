module Follower
  extend ActiveSupport::Concern
  include FederailsCommon

  included do
    acts_as_federails_actor username_field: :username, name_field: :name
    delegate :activities, to: :actor
    delegate :following_follows, to: :actor
  end

  def follows
    actor.follows.map(&:user)
  end

  def follow(target)
    target.create_actor_if_missing
    following_follows.create(target_actor: target.actor)
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
