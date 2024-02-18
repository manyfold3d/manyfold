class LibraryPolicy < ActiveAdminPolicy
  def create?
    !SiteSettings.demo_mode?
  end

  def update?
    !SiteSettings.demo_mode?
  end

  def destroy?
    !SiteSettings.demo_mode?
  end
end
