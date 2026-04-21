require "federails/data_transformer/note"

class Comment < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.comment")

  include PublicIDable
  include Federails::DataEntity
  include Reportable

  belongs_to :commenter, polymorphic: true, optional: true
  belongs_to :commentable, polymorphic: true

  acts_as_federails_data handles: "Note", actor_entity_method: :commenter, url_param: :public_id, should_federate_method: :federate?, route_path_segment: :comments
  on_federails_delete_requested :federated_delete

  def to_activitypub_object
    ActivityPub::CommentSerializer.new(self).serialize
  end

  def federate?
    ActivityPub::CommentSerializer.new(self).federate?
  end

  def public?
    (!commenter&.local? || commenter&.public?) && commentable&.public?
  end

  def name
    "#{created_at} @ #{commentable.name}"
  end

  def self.handle_federated_object?(note)
    ActivityPub::CommentDeserializer.can_handle?(note)
  end

  def self.from_activitypub_object(note)
    ActivityPub::CommentDeserializer.new(note).send :deserialize
  rescue ActiveRecord::RecordNotFound
    {}
  end

  def federated_delete
    destroy
  end

  def on_new_quote_request(quote_authorization)
    # Auto accept quote requests for system comments
    system ? quote_authorization.accept! : quote_authorization.reject!
  end
end
