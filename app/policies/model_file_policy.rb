class ModelFilePolicy < ActiveAdminPolicy
  def destroy?
    !SiteSettings.demo_mode?
  end
end
