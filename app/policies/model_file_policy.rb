class ModelFilePolicy < ApplicationPolicy
  def show?
    true
  end

  def destroy?
    !Flipper.enabled?(:demo_mode)
  end

  def bulk_edit?
    true
  end

  def bulk_update?
    true
  end
end
