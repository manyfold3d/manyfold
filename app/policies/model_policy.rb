class ModelPolicy < ApplicationPolicy
  def merge?
    all_of(
      one_of(
        user&.is_moderator?,
        check_permissions(record, ["editor", "owner"], user)
      ),
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def scan?
    user&.is_contributor?
  end

  def bulk_edit?
    user&.is_moderator?
  end

  def bulk_update?
    user&.is_moderator?
  end
end
