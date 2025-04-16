class UploadPolicy < ApplicationPolicy
  def index?
    create?
  end

  def create?
    all_of(
      user&.is_contributor?,
      user.has_quota? ? user.current_space_used < user.quota : true,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end
end
