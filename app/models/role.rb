class Role < ApplicationRecord
  include Caber::Subject

  can_have_permissions_on Creator
  can_have_permissions_on Collection
  can_have_permissions_on Model

  ROLES = [
    :administrator,   # Can do everything
    :editor,          # Can edit any models
    :contributor,     # Can upload models and edit their own
    :viewer           # Can view models; read only access
  ]

  has_many :users, through: :users_roles

  belongs_to :resource,
    polymorphic: true,
    optional: true

  validates :resource_type,
    inclusion: {in: Rolify.resource_types},
    allow_nil: true

  validates :name,
    inclusion: {in: ROLES.map(&:to_s)}

  scopify
end
