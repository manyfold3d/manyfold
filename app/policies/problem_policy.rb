class ProblemPolicy < ApplicationPolicy
  def index?
    user&.is_contributor?
  end

  def show?
    user&.is_contributor?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
