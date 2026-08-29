# frozen_string_literal: true

class PrintHostPolicy < ApplicationPolicy
  def index?
    user&.is_administrator?
  end

  def show?
    index?
  end

  def create?
    all_of(
      user&.is_administrator?,
      none_of(SiteSettings.demo_mode_enabled?)
    )
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  # Mutating printer control (upload / start / pause / stop / continue).
  def control?
    create?
  end

  def discover?
    index?
  end

  def storage?
    control?
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
