class ScanPolicy < ApplicationPolicy
  def create?
    user&.is_administrator?
  end
end
