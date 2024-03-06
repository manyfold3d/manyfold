class ModelPolicy < ApplicationPolicy
  def destroy?
    !Flipper.enabled? :demo_mode
  end
end
