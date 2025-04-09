class ProblemPolicy < ApplicationPolicy
  def index?
    user&.is_contributor?
  end

  def show?
    user&.is_contributor?
  end

  def resolve?
    Pundit::PolicyFinder.new(record.problematic).policy.new(user, record.problematic).send(:"#{record.resolution_strategy}?")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
    end
  end
end
