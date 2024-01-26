class UploadPolicy < ApplicationPolicy
  def index?
    !SiteSettings.demo_mode?
  end

  def create?
    !SiteSettings.demo_mode?
  end
end
