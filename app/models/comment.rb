class Comment < ApplicationRecord
  include PublicIDable

  belongs_to :commenter, polymorphic: true
  belongs_to :commentable, polymorphic: true
  def federated_url
    Rails.application.routes.url_helpers.url_for([commentable, self, {only_path: false}])
  end

end
