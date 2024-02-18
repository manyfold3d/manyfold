class ModelPolicy < ActiveAdminPolicy
  def destroy?
    !SiteSettings.demo_mode?
  end
end
