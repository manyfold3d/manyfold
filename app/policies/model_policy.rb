class ModelPolicy < ApplicationPolicy
  def show?
    super && !(user&.sensitive_content_handling == "hide" && record.sensitive)
  end

  def merge?
    all_of(
      one_of(
        user&.is_moderator?,
        check_permissions(record, ["edit", "own"], user)
      ),
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def destroy?
    super && (record.is_a?(Model) ? !record.contains_other_models? : true)
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.sensitive_content_handling == "hide"
        super.where(sensitive: false)
      else
        super
      end
    end
  end
end
