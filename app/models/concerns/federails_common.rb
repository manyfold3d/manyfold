module FederailsCommon
  extend ActiveSupport::Concern
  include Federails::Entity

  def create_actor_if_missing
    return if actor.present?
    create_actor
    reload
  end
end
