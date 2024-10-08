class Comment < ApplicationRecord
  include PublicIDable

  belongs_to :commenter, polymorphic: true
  belongs_to :commentable, polymorphic: true
end
