class Doorkeeper::ApplicationPolicy < ApplicationPolicy
  def index?
    user&.is_contributor?
  end

  def show?
    one_of(
      record.owner == user,
      user&.is_moderator?
    )
  end

  def create?
    all_of(
      user&.is_contributor?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def update?
    all_of(
      one_of(
        user == record,
        user&.is_administrator?
      ),
      SiteSettings.multiuser_enabled?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def destroy?
    update?
  end

  def revoke_token?
    update?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      user&.is_moderator? ? scope : scope.where(owner: user)
    end
  end
end
