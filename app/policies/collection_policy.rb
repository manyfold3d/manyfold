class CollectionPolicy < ApplicationPolicy
  alias_method :cover?, :show?

  def sync?
    update?
  end
end
