class ModelFilePolicy < ApplicationPolicy
  def show?
    ModelPolicy.new(@user, @record.model).show?
  end

  def create?
    ModelPolicy.new(@user, @record.model).edit?
  end

  def update?
    create?
  end

  def delete?
    create?
  end

  def bulk_edit?
    bulk_update?
  end

  def bulk_update?
    create?
  end
end
