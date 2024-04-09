# frozen_string_literal: true

class SetAdminPasswordResetToken < ActiveRecord::Migration[7.0]
  def up
    u = User.with_role(:administrator).first
    if u
      u.reset_password_token = "first_use"
      u.save validate: false
    end
  end

  def down
  end
end
