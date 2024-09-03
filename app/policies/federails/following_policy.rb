class Federails::FollowingPolicy < ApplicationPolicy
  def create?
    all_of(
      one_of(
        SiteSettings.multiuser_enabled?,
        SiteSettings.federation_enabled?
      ),
      @user
    )
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
