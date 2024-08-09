class Federails::FollowingPolicy < ApplicationPolicy
  def create?
    all_of(
      SiteSettings.multiuser_enabled?
    )
  end

  def destroy?
    all_of(
      SiteSettings.multiuser_enabled?
    )
  end

  class Scope < ApplicationPolicy::Scope
  end
end
