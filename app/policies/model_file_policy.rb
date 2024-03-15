class ModelFilePolicy < ApplicationPolicy
  def show?
    true
  end

  def destroy?
    !Flipper.enabled?(:demo_mode)
  end
end
