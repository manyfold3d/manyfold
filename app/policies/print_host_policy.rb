class PrintHostPolicy < ApplicationPolicy
  def index?
    all_of(
      user&.is_administrator?,
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
    index?
  end
end
