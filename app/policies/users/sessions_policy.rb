# frozen_string_literal: true

class Users::SessionsPolicy < ApplicationPolicy
  def new?
    true # different from create? to allow autologin
  end

  def create?
    Flipper.enabled?(:multiuser)
  end

  def destroy?
    Flipper.enabled?(:multiuser)
  end
end
