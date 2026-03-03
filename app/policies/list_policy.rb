class ListPolicy < ApplicationPolicy
  def create?
    user.present?
  end
end
