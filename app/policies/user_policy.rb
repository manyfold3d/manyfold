class UserPolicy < ApplicationPolicy
  def index?
    [
      user.admin?,
      !Flipper.enabled?(:demo_mode)
    ].all?
  end

  def show?
    [
      [
        user == record,
        user.admin?
      ].any?,
      !Flipper.enabled?(:demo_mode)
    ].all?
  end

  def create?
    [
      [
        SiteSettings.registration_enabled,
        user&.admin?
      ].any?,
      Flipper.enabled?(:multiuser),
      !Flipper.enabled?(:demo_mode)
    ].all?
  end

  def update?
    [
      user == record,
      user.admin?
    ].any?
  end

  def destroy?
    [
      [
        user == record,
        user&.admin?
      ].any?,
      Flipper.enabled?(:multiuser),
      !Flipper.enabled?(:demo_mode)
    ].all?
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
