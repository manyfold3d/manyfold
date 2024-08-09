# frozen_string_literal: true

class Users::SessionsPolicy < ApplicationPolicy
  def new?
    true # different from create? to allow autologin
  end

  def create?
    SiteSettings.multiuser_enabled?
  end

  def destroy?
    SiteSettings.multiuser_enabled?
  end
end
