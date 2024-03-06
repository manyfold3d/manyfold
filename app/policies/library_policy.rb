class LibraryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    !Flipper.enabled? :demo_mode
  end

  def update?
    !Flipper.enabled? :demo_mode
  end

  def destroy?
    !Flipper.enabled? :demo_mode
  end
end
