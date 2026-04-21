class Federails::QuoteAuthorization < ApplicationRecord
  def self.table_name_prefix
    "federails_"
  end

  belongs_to :interaction_target, polymorphic: true
  belongs_to :federails_actor, class_name: "Federails::Actor"
  belongs_to :quoting_actor, class_name: "Federails::Actor"

  before_create :generate_uuid

  def accept!
    update!(state: "accepted")
  end

  def reject!
    update!(state: "rejected")
  end

  def to_activitypub_object
    {
      type: "QuoteRequest",
      id: quote_request_url,
      actor: quoting_actor.federated_url,
      object: interaction_target.federated_url,
      instrument: interacting_object_url
    }
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
