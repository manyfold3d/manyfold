module FederailsCommon
  extend ActiveSupport::Concern
  include Federails::ActorEntity

  # Listed in increasing order of priority
  FEDIVERSE_USERNAMES = {
    collection: :public_id,
    model: :public_id,
    creator: :slug,
    user: :username
  }

  def federails_actor
    act = Federails::Actor.find_by(entity: self)
    if act.nil?
      act = create_federails_actor
      reload
    end
    act
  end

  def remote?
    !federails_actor&.local?
  end
end
