class ModelFilePolicy < ApplicationPolicy
  def show?
    return false unless ModelPolicy.new(@user, @record.model).show?
    @record.previewable? || check_permissions(@record.model, ["view", "edit", "own"], @user)
  end

  def create?
    ModelPolicy.new(@user, @record.model).edit?
  end

  def convert?
    create? && @record.loadable? && !@record.problems.exists?(category: :non_manifold)
  end

  def update?
    create?
  end

  def delete?
    create?
  end

  def bulk_edit?
    bulk_update?
  end

  def bulk_update?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    FULL_VIEW_PERMISSIONS = ["view", "edit", "own"]

    def resolve
      subject_list = [nil, user, user&.roles].flatten
      scope
        # Where the user only has preview permissions, then show previewable files
        .where(previewable: true)
        .where(model: Model.granted_to("preview", subject_list))
        .where.not(model: Model.granted_to(FULL_VIEW_PERMISSIONS, subject_list))
        # Otherwise, show files where the user has full view permissions on the model
        .or(
          scope.where(model: Model.granted_to(FULL_VIEW_PERMISSIONS, subject_list))
        )
    end
  end
end
