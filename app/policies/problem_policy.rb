class ProblemPolicy < ApplicationPolicy
  def index?
    user&.is_moderator?
  end

  def show?
    user&.is_moderator?
  end

  def resolve?
    all_of(
      user&.is_moderator?,
      Pundit::PolicyFinder.new(record.problematic).policy.new(user, record.problematic).send(:"#{record.resolution_strategy}?")
    )
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      @user.is_moderator? ? scope : scope.none
    end
  end
end
