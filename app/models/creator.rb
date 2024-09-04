class Creator < ApplicationRecord
  include Followable
  include CaberObject
  include Linkable
  include Sluggable
  include CoolId::Model

  cool_id prefix: "cr", id_field: :public_id
  def to_param
    public_id
  end

  acts_as_federails_actor username_field: :slug, name_field: :name, profile_url_method: :url_for, include_in_user_count: false

  has_many :models, dependent: :nullify
  validates :name, uniqueness: {case_sensitive: false}

  default_scope { order(:name) }

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "id", "name", "notes", "slug", "updated_at"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["links", "models"]
  end
end
