class Role < ApplicationRecord
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
