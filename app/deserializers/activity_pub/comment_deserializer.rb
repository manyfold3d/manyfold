module ActivityPub
  class CommentDeserializer < ApplicationDeserializer
    def initialize(object)
      super
      @sanitizer = Rails::HTML5::FullSanitizer.new
    end

    def self.can_handle?(object)
      return false unless object["type"] == "Note"
      return false if object["f3di:compatibilityNote"] == "true"
      return false if object["inReplyTo"].blank?
      true
    end

    def create!
      Comment.create!(deserialize)
    end

    private

    def get_actor
      Federails::Actor.find_or_create_by_federation_url @object["attributedTo"]
    end

    def commentable
      public_id = @object["inReplyTo"]&.split("/")&.last
      return nil if public_id.nil?
      Comment.find_by(public_id: public_id)&.commentable || Federails::Actor.find_by(uuid: public_id)&.entity
    end

    def content
      @sanitizer.sanitize(@object["content"])
    end

    def deserialize
      commenter = get_actor
      {
        federails_actor: commenter,
        commenter: commenter.entity || commenter,
        commentable: commentable,
        comment: content
      }
    end
  end
end
