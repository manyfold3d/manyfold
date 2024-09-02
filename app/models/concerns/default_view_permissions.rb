module DefaultViewPermissions
  extend ActiveSupport::Concern

  included do
    after_create :assign_default_permissions
  end

  def assign_default_permissions
    # Grant local view access by default
    role = SiteSettings.default_viewer_role
    grant_permission_to("view", Role.find_or_create_by(name: role)) if role
    # Set default owner
    owner = SiteSettings.default_user
    grant_permission_to("own", owner) if owner
  end
end
