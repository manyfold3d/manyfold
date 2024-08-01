class Federails::FollowingPolicy < ApplicationPolicy
  def create?
    all_of(
      Flipper.enabled?(:multiuser)
    )
  end

  def destroy?
    all_of(
      Flipper.enabled?(:multiuser)
    )
  end

  class Scope < ApplicationPolicy::Scope
  end
end
