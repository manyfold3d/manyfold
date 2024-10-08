module CaberObject
  extend ActiveSupport::Concern
  include Caber::Object

  included do
    can_grant_permissions_to User
    can_grant_permissions_to Role

    accepts_nested_attributes_for :caber_relations, reject_if: :all_blank, allow_destroy: true

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
