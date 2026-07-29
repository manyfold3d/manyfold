module FedipubCommon
  extend ActiveSupport::Concern
  include Fedipub::ActorEntity

  included do
    scope :local, -> { includes(:fedipub_actor).where("fedipub_actor.local": true) }
    scope :remote, -> { includes(:fedipub_actor).where("fedipub_actor.local": false) }
  end

  # Listed in increasing order of priority
  FEDIVERSE_USERNAMES = {
    collection: :public_id,
    model: :public_id,
    creator: :slug,
    user: :username,
    list: :public_id
  }

  def fedipub_actor
    return nil unless DatabaseDetector.table_ready? "fedipub_actors"
    return nil unless persisted?
    act = Fedipub::Actor.find_by(entity: self)
    if act.nil?
      act = create_fedipub_actor
      reload
    end
    act
  rescue NoMethodError, ActiveRecord::StatementInvalid
    # Just return nil if we get errors from not running on fully-migrated data
    nil
  end

  def local?
    fedipub_actor ? fedipub_actor.local? : true
  end

  def remote?
    !local?
  end
end
