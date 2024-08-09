# frozen_string_literal: true

class Users::PasswordsPolicy < ApplicationPolicy
  def create?
    SiteSettings.multiuser_enabled? && SiteSettings.email_configured?
  end

  def update?
    SiteSettings.multiuser_enabled? && SiteSettings.email_configured?
  end
end
