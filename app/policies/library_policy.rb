class LibraryPolicy < ApplicationPolicy
  def create?
    !Flipper.enabled?(:demo_mode) && user&.is_administrator?
  end

  def update?
    !Flipper.enabled?(:demo_mode) && user&.is_administrator?
  end

  def destroy?
    !Flipper.enabled?(:demo_mode) && user&.is_administrator?
  end

  def scan?
    user&.is_contributor?
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
