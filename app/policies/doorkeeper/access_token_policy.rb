class Doorkeeper::AccessTokenPolicy < ApplicationPolicy
  def show?
    one_of(
      record.application.owner == user,
      user&.is_moderator? && !record.application.owner&.is_administrator?
    )
  end

  def new?
    create?
  end

  def create?
    all_of(
      show?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def destroy?
    show?
  end
end
