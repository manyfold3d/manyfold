class Role < ApplicationRecord
  include CaberSubject

  ROLES = [
    :administrator,   # Can do everything
    :moderator,       # Can edit any models
    :contributor,     # Can upload models and edit their own
    :member           # Can view models; read only access
  ]

  has_many :users, through: :users_roles

  belongs_to :resource,
    polymorphic: true,
    optional: true

  validates :resource_type,
    inclusion: {in: Rolify.resource_types},
    allow_nil: true

  validates :name,   # rubocop:todo Rails/UniqueValidationWithoutIndex
    inclusion: {in: ROLES.map(&:to_s)},
    uniqueness: true

  scopify

  def self.merge_duplicates!
    ActiveRecord::Base.transaction do
      ROLES
        .map { |n| Role.where(name: n) } # rubocop:disable Pundit/UsePolicyScope
        .select { |r| r.count > 1 }
        .each do |roles|
          original, *duplicates = roles.order(created_at: :desc)
          Caber::Relation.where(subject_type: "Role", subject_id: duplicates.map(&:id)).update_all(subject_id: original.id) # rubocop:disable Rails/SkipsModelValidations, Pundit/UsePolicyScope
          duplicates.each do |dupe|
            # Rename duplicate role to something different
            dupe.update_attribute :name, "#{dupe.name}##{dupe.id}"  # rubocop:disable Rails/SkipsModelValidations
            # Find all users with the new named role
            # and give them the original role, before removing the dupe
            User.with_role(dupe.name).each do |user|
              user.add_role(original.name)
            end
            dupe.destroy
          end
        end
    end
  end
end
