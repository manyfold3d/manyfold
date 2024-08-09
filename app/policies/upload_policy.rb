class UploadPolicy < ApplicationPolicy
  def index?
    create?
  end

  def create?
    all_of(
      user&.is_contributor?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end
end
