# frozen_string_literal: true

class Users::RegistrationsPolicy < ApplicationPolicy
  def create?
    Flipper.enabled?(:multiuser) &&
      SiteSettings.registration_enabled &&
      user.nil?
  end

  def update?
    user == record
  end

  def destroy?
    Flipper.enabled?(:multiuser) && (user == record)
  end
end
