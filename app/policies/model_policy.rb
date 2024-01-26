class ModelPolicy < ApplicationPolicy
  def destroy?
    !SiteSettings.demo_mode?
  end
end
