class LibraryPolicy < ApplicationPolicy
  def index?
    all_of(
      user&.is_administrator?
    )
  end

  def create?
    all_of(
      user&.is_administrator?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def update?
    create?
  end

  def destroy?
    create?
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
