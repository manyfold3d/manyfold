# frozen_string_literal: true

class Users::PasswordsPolicy < ApplicationPolicy
  def create?
    Flipper.enabled?(:multiuser)
  end

  def update?
    Flipper.enabled?(:multiuser)
  end
end
