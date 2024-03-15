class UserPolicy < ApplicationPolicy
  def index?
    !Flipper.enabled?(:demo_mode)
  end

  def show?
    !Flipper.enabled?(:demo_mode)
  end

  def create?
    !Flipper.enabled?(:demo_mode)
  end

  def update?
    !Flipper.enabled?(:demo_mode)
  end

  def destroy?
    !Flipper.enabled?(:demo_mode)
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
