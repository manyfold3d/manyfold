module FederailsCommon
  extend ActiveSupport::Concern
  include Federails::ActorEntity

  included do
    scope :local, -> { includes(:federails_actor).where("federails_actor.local": true) }
    scope :remote, -> { includes(:federails_actor).where("federails_actor.local": false) }
  end

  # Listed in increasing order of priority
  FEDIVERSE_USERNAMES = {
    collection: :public_id,
    model: :public_id,
    creator: :slug,
    user: :username
  }

  def federails_actor
    return nil unless ActiveRecord::Base.connection.data_source_exists? "federails_actors"
    return nil unless persisted?
    act = Federails::Actor.find_by(entity: self)
    if act.nil?
      act = create_federails_actor
      reload
    end
    act
  rescue NoMethodError
    # Just return nil if we get errors from not running on fully-migrated data
    nil
  end

  def local?
    federails_actor ? federails_actor.local? : true
  end

  def remote?
    !local?
  end
end
