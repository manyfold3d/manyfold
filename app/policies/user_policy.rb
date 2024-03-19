class UserPolicy < ApplicationPolicy
  def index?
    all_of(
      user.admin?,
      none_of(
        Flipper.enabled?(:demo_mode)
      )
    )
  end

  def show?
    all_of(
      one_of(
        user == record,
        user.admin?
      ),
      none_of(
        Flipper.enabled?(:demo_mode)
      )
    )
  end

  def create?
    all_of(
      Flipper.enabled?(:multiuser),
      one_of(
        SiteSettings.registration_enabled,
        user&.admin?
      ),
      none_of(
        Flipper.enabled?(:demo_mode)
      )
    )
  end

  def update?
    one_of(
      user == record,
      user.admin?
    )
  end

  def destroy?
    all_of(
      one_of(
        user == record,
        user&.admin?
      ),
      Flipper.enabled?(:multiuser),
      none_of(
        Flipper.enabled?(:demo_mode)
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
