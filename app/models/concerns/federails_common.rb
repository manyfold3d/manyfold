module FederailsCommon
  extend ActiveSupport::Concern
  include Federails::ActorEntity

  def federails_actor
    act = Federails::Actor.find_by(entity: self)
    if act.nil?
      act = create_federails_actor
      reload
    end
    act
  end
end
