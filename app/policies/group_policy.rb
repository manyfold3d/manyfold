class GroupPolicy < ApplicationPolicy
  def show?
    @user.has_permission_on?("own", @record.creator) || @user.is_moderator?
  end

  alias_method :create?, :show?
  alias_method :update?, :show?
  alias_method :destroy?, :show?
end
