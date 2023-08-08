# frozen_string_literal: true

class Favorite < ApplicationRecord
  extend ActsAsFavoritor::FavoriteScopes

  belongs_to :favoritable, polymorphic: true
  belongs_to :favoritor, polymorphic: true

  def block!
    update!(blocked: true)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["blocked", "created_at", "favoritable_id", "favoritable_type", "favoritor_id", "favoritor_type", "id", "scope", "updated_at"]
  end
end
