class ListPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    record.special.nil? && super
  end
end
