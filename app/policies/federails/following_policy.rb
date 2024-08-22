class Federails::FollowingPolicy < ApplicationPolicy
  def create?
    any_of(
      SiteSettings.multiuser_enabled?,
      SiteSettings.federation_enabled?
    )
  end

  def destroy?
    any_of(
      SiteSettings.multiuser_enabled?,
      SiteSettings.federation_enabled?
    )
  end

  class Scope < ApplicationPolicy::Scope
  end
end
