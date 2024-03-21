class LibraryPolicy < ApplicationPolicy
  def create?
    all_of(
      user&.is_administrator?,
      none_of(
        Flipper.enabled?(:demo_mode)
      )
    )
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def scan?
    user&.is_contributor?
  end

  def scan_all?
    scan?
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
