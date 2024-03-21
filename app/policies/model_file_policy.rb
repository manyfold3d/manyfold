class ModelFilePolicy < ApplicationPolicy
  def bulk_edit?
    user&.is_editor?
  end

  def bulk_update?
    user&.is_editor?
  end
end
