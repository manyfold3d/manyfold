class CommentPolicy < ApplicationPolicy
  def create?
    all_of(
      user.present?,
      one_of(
        user&.is_moderator?,
        check_permissions(record.commentable, STANDARD_VIEW_PERMISSIONS, user)
      )
    )
  end

  def destroy?
    one_of(
      user&.is_moderator?,
      record.commenter == user
    )
  end
end
