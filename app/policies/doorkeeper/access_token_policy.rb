class Doorkeeper::AccessTokenPolicy < ApplicationPolicy
  def show?
    one_of(
      record.application.owner == user,
      user&.is_moderator?
    )
  end

  def create?
    all_of(
      record.application.owner == user,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def destroy?
    one_of(
      record.application.owner == user,
      user&.is_moderator?
    )
  end
end
