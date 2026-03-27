require "federails/data_transformer/note"

class Comment < ApplicationRecord
  include PublicIDable
  include Federails::DataEntity
  include Reportable

  belongs_to :commenter, polymorphic: true, optional: true
  belongs_to :commentable, polymorphic: true

  acts_as_federails_data handles: "Note", actor_entity_method: :commenter, url_param: :public_id, should_federate_method: :federate?

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
    nil
  end
end
