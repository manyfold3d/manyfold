class CreatorPolicy < ApplicationPolicy
  alias_method :sync?, :update?
  alias_method :avatar?, :show?
  alias_method :banner?, :show?
end
