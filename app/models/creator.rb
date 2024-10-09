class Creator < ApplicationRecord
  include Followable
  include CaberObject
  include Linkable
  include Sluggable
  include PublicIDable
  include Commentable

  acts_as_federails_actor username_field: :slug, name_field: :name, profile_url_method: :url_for, include_in_user_count: false

  has_many :models, dependent: :nullify
  validates :name, uniqueness: {case_sensitive: false}

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "id", "public_id", "name", "notes", "slug", "updated_at"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["links", "models"]
  end
end
