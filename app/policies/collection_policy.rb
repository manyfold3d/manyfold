class CollectionPolicy < ApplicationPolicy
  def sync?
    update?
  end
end
