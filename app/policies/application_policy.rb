# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  STANDARD_VIEW_PERMISSIONS = ["preview", "view", "edit", "own"]
  STANDARD_EDIT_PERMISSIONS = ["edit", "own"]

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
      check_permissions(record, STANDARD_VIEW_PERMISSIONS, user, role_fallback: :member)
    )
  end

  def create?
    user&.is_contributor?
  end

  def new?
    create?
  end

  def update?
    all_of(
      record.respond_to?(:local?) ? record.local? : true,
      one_of(
        user&.is_moderator?,
        check_permissions(record, STANDARD_EDIT_PERMISSIONS, user, role_fallback: :moderator)
      )
    )
  end

  def edit?
    update?
  end

  def destroy?
    all_of(
      one_of(
        user&.is_moderator?,
        check_permissions(record, STANDARD_EDIT_PERMISSIONS, user, role_fallback: :moderator)
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
      return scope if user&.is_moderator? || !scope.respond_to?(:granted_to)

      result = scope.granted_to(STANDARD_VIEW_PERMISSIONS, [user, nil])
      result = result.or(scope.granted_to(STANDARD_VIEW_PERMISSIONS, user.roles)) if user
      result = result.or(scope.granted_to(STANDARD_VIEW_PERMISSIONS, user.groups)) if user
      result
    end

    private

    attr_reader :user, :scope
  end

  class UpdateScope < Scope
    def resolve
      return scope.local if user&.is_moderator? || !scope.respond_to?(:granted_to)

      result = scope.granted_to(STANDARD_EDIT_PERMISSIONS, [user, nil])
      result = result.or(scope.granted_to(STANDARD_EDIT_PERMISSIONS, user.roles)) if user
      result = result.or(scope.granted_to(STANDARD_EDIT_PERMISSIONS, user.groups)) if user
      result.local
    end
  end

  class OwnerScope < Scope
    def resolve
      scope.granted_to("own", user).local
    rescue NoMethodError
      scope.none
    end
  end

  private

  def check_permissions(record, permissions, user, role_fallback: nil)
    record.grants_permission_to?(permissions, [user, user&.roles, user&.groups].flatten)
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
