class ScanPolicy < ApplicationPolicy
  def create?
    user&.is_contributor?
  end
end
