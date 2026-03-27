module ActivityPub
  class CommentDeserializer < ApplicationDeserializer
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

    def deserialize
      {}
    end
  end
end
