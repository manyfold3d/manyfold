class SettingsPolicy < ApplicationPolicy
  def show?
    update?
  end

  def analysis?
    update?
  end

  def appearance?
    update?
  end

  def multiuser?
    update?
  end

  def reporting?
    update?
  end

  def update?
    one_of(
      user&.is_administrator?
    )
  end
end
