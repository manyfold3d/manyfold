# frozen_string_literal: true

class Users::RegistrationsPolicy < ApplicationPolicy
  def cancel?
    Flipper.enabled?(:multiuser)
  end
end
