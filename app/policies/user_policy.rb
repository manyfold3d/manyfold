class UserPolicy < ApplicationPolicy
  def index?
    all_of(
      user&.is_moderator?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def show?
    all_of(
      one_of(
        user == record,
        user&.is_moderator?
      )
    )
  end

  def create?
    all_of(
      SiteSettings.multiuser_enabled?,
      one_of(
        SiteSettings.registration_enabled?,
        user&.is_moderator?
      ),
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def update?
    one_of(
      user == record,
      user&.is_moderator?
    )
  end

  def destroy?
    all_of(
      one_of(
        user == record,
        user&.is_administrator?
      ),
      SiteSettings.multiuser_enabled?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
