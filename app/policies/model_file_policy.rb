class ModelFilePolicy < ApplicationPolicy
  def show?
    return false unless ModelPolicy.new(@user, @record.model).show?
    @user&.is_moderator? || @record.previewable? || check_permissions(@record.model, ["view", "edit", "own"], @user)
  end

  def create?
    can_update_model?
  end

  def convert?
    can_update_model? && @record.loadable? && !@record.problems.exists?(category: :non_manifold)
  end

  def update?
    can_update_model?
  end

  def destroy?
    can_update_model?
  end

  def bulk_edit?
    bulk_update?
  end

  def bulk_update?
    can_update_model?
  end

  class Scope < ApplicationPolicy::Scope
    FULL_VIEW_PERMISSIONS = ["view", "edit", "own"]

    def resolve
      return scope if @user&.is_moderator?
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

  private

  def can_update_model?
    ModelPolicy.new(@user, @record.model).update?
  end
end
