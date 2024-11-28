class Federails::Moderation::DomainBlockPolicy < ApplicationPolicy
  def index?
    all_of(
      SiteSettings.federation_enabled?,
      @user.is_moderator?
    )
  end

  def show?
    index?
  end

  def edit?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
