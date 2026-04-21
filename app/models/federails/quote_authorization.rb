class Federails::QuoteAuthorization < ApplicationRecord
  def self.table_name_prefix
    "federails_"
  end

  belongs_to :interaction_target, polymorphic: true
  belongs_to :federails_actor, class_name: "Federails::Actor"
  belongs_to :quoting_actor, class_name: "Federails::Actor"

  before_create :generate_uuid

  def to_param
    uuid
  end

  def accept!
    update!(state: "accepted")
    create_response_activity
  end

  def reject!
    update!(state: "rejected")
    create_response_activity
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

  def create_response_activity
    Federails::Activity.create!(
      actor: federails_actor,
      action: (state == "accepted") ? "Accept" : "Reject",
      entity: self,
      to: quoting_actor.federated_url
    )
  end

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
