class Membership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  validates :user, uniqueness: {scope: :group} # rubocop:disable Rails/UniqueValidationWithoutIndex
end
