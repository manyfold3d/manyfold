class PrintHostPolicy < ApplicationPolicy
  def index?
    all_of(
      @user&.is_administrator?,
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def print?
    all_of(
      one_of(
        @user&.is_printer?,
        @user&.is_administrator?
      ),
      none_of(
        SiteSettings.demo_mode_enabled?
      )
    )
  end
end
