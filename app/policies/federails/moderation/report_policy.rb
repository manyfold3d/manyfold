class Federails::Moderation::ReportPolicy < ApplicationPolicy
  def index?
    all_of(
      SiteSettings.multiuser_enabled?,
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
