class ActivityPolicy < ApplicationPolicy
  def index?
    user&.is_administrator?
  end
end
