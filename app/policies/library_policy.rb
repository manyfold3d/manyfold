class LibraryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    !Flipper.enabled?(:demo_mode) && user.admin?
  end

  def update?
    !Flipper.enabled?(:demo_mode) && user.admin?
  end

  def destroy?
    !Flipper.enabled?(:demo_mode) && user.admin?
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
