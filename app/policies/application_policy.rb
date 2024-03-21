# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user&.is_administrator?
  end

  def show?
    user&.is_administrator?
  end

  def create?
    user&.is_administrator?
  end

  def new?
    create?
  end

  def update?
    user&.is_administrator?
  end

  def edit?
    update?
  end

  def destroy?
    user&.is_administrator?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    attr_reader :user, :scope
  end

  private

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
