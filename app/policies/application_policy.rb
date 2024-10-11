# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    show?
  end

  def show?
    one_of(
      user&.is_moderator?,
      check_permissions(record, ["view", "edit", "own"], user, role_fallback: :member)
    )
  end

  def create?
    user&.is_contributor?
  end

  def new?
    create?
  end

  def update?
    one_of(
      user&.is_moderator?,
      check_permissions(record, ["edit", "own"], user, role_fallback: :moderator)
    )
  end

  def edit?
    update?
  end

  def destroy?
    all_of(
      one_of(
        user&.is_moderator?,
        check_permissions(record, ["edit", "own"], user, role_fallback: :moderator)
      ),
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def destroy_all?
    user&.is_administrator?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user&.is_moderator? || !scope.respond_to?(:granted_to)

      result = scope.granted_to(["view", "edit", "own"], [user, nil])
      result = result.or(scope.granted_to(["view", "edit", "own"], user.roles)) if user
      result
    end

    private

    attr_reader :user, :scope
  end

  private

  def check_permissions(record, permissions, user, role_fallback: nil)
    record.grants_permission_to?(permissions, [user, user&.roles].flatten)
  rescue NoMethodError
    user&.has_role?(role_fallback)
  end

  def one_of(*args)
    args.any?
  end

  def all_of(*args)
    args.all?
  end

  def none_of(*args)
    args.none?
  end
end
