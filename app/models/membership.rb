class Membership < ApplicationRecord
  # i18n-tasks-use t("activerecord.models.membership")

  belongs_to :group
  belongs_to :user

  validates :user, uniqueness: {scope: :group} # rubocop:disable Rails/UniqueValidationWithoutIndex
end
