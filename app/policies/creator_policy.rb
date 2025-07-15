class CreatorPolicy < ApplicationPolicy
  def sync?
    update?
  end
end
