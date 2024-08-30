class ModelPolicy < ApplicationPolicy
  def merge?
    all_of(
      one_of(
        user&.is_editor?,
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
    user&.is_editor?
  end

  def bulk_update?
    user&.is_editor?
  end
end
