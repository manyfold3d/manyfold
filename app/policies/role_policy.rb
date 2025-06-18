class RolePolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      user&.is_administrator? ? scope : scope.where(name: [:member, :contributor])
    end
  end
end
