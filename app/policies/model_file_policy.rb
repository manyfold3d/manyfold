class ModelFilePolicy < ApplicationPolicy
  def bulk_edit?
    user&.is_moderator?
  end

  def bulk_update?
    user&.is_moderator?
  end
end
