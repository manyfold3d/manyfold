module DefaultViewPermissions
  extend ActiveSupport::Concern

  included do
    after_create :assign_default_view_permissions
  end

  def assign_default_view_permissions
    grant_permission_to("viewer", Role.find_by(name: :viewer))
  end
end
