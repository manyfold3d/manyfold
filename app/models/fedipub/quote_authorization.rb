class Fedipub::QuoteAuthorization < ApplicationRecord
  def self.table_name_prefix
    "fedipub_"
  end

  belongs_to :interaction_target, polymorphic: true
  belongs_to :fedipub_actor, class_name: "Fedipub::Actor"
  belongs_to :quoting_actor, class_name: "Fedipub::Actor"

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
    Fedipub::Activity.create!(
      actor: fedipub_actor,
      action: (state == "accepted") ? "Accept" : "Reject",
      entity: self,
      to: quoting_actor.federated_url,
      result: (state == "accepted") ? Rails.application.routes.url_helpers.fedipub_server_quote_authorization_url(self) : nil
    )
  end

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
