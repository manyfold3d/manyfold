# frozen_string_literal: true

class SetAdminPasswordResetToken < ActiveRecord::Migration[7.0]
  def up
    u = User.with_role(:administrator).first
    u&.update!(reset_password_token: "first_use")
  end

  def down
  end
end
