class ModelPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def merge?
    all_of(
      user&.is_editor?,
      none_of(
        Flipper.enabled?(:demo_mode)
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
