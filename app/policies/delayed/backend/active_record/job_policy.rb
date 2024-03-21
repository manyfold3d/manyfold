# frozen_string_literal: true

class Delayed::Backend::ActiveRecord::JobPolicy < ApplicationPolicy
  def index?
    user&.is_administrator?
  end

  def show?
    user&.is_administrator?
  end

  def create?
    user&.is_administrator?
  end

  def update?
    user&.is_administrator?
  end

  def destroy?
    user&.is_administrator?
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
