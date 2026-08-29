# frozen_string_literal: true

class PrintVatPolicy < ApplicationPolicy
  def index?
    user&.is_administrator?
  end

  def show?
    index?
  end

  def create?
    mutate?
  end

  def update?
    mutate?
  end

  def destroy?
    mutate?
  end

  def mutate?
    all_of(
      user&.is_administrator?,
      none_of(SiteSettings.demo_mode_enabled?)
    )
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      user&.is_administrator? ? scope.all : scope.none
    end
  end
end
