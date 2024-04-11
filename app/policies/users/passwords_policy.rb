# frozen_string_literal: true

class Users::PasswordsPolicy < ApplicationPolicy
  def create?
    Flipper.enabled?(:multiuser) && SiteSettings.email_configured
  end

  def update?
    Flipper.enabled?(:multiuser) && SiteSettings.email_configured
  end
end
