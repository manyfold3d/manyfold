# frozen_string_literal: true

class Users::RegistrationsPolicy < ApplicationPolicy
  def cancel?
    SiteSettings.multiuser_enabled?
  end
end
