class LibraryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

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
    true
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
