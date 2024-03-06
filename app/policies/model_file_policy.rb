class ModelFilePolicy < ApplicationPolicy
  def destroy?
    !Flipper.enabled? :demo_mode
  end
end
