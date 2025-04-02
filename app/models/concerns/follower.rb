module Follower
  extend ActiveSupport::Concern
  include FederailsCommon

  included do
    delegate :activities, to: :federails_actor
    delegate :following_follows, to: :federails_actor

    after_follow_accepted :after_accept
  end

  def follow(target)
    following_follows.create(target_actor: target.is_a?(Federails::Actor) ? target : target.federails_actor)
  end

  def unfollow(target)
    f = federails_actor.follows?(target.is_a?(Federails::Actor) ? target : target.federails_actor)
    f&.destroy unless f == false
  end

  def following?(target)
    # follows? gives us the relationship or false if it doesn't exist,
    # we turn that into the pendingstatus (or false if not)
    tgt = target.is_a?(Federails::Actor) ? target : target.federails_actor
    f = federails_actor&.follows?(tgt)
    f&.is_a?(Federails::Following) ? f.status.to_sym : false
  end

  private

  def after_accept(follow)
    find_or_create_followed_entity(follow.target_actor)
  end

  def find_or_create_followed_entity(actor)
    actor.entity || ActivityPub::ApplicationDeserializer.deserializer_for(actor)&.create!
  end
end
