# frozen_string_literal: true

class CreateDefaultAdminUser < ActiveRecord::Migration[7.0]
  def up
    User.create(
      username: "admin",
      email: "nobody@example.com",
      admin: true
    )
  end

  def down
    User.find_by_username("admin").destroy
  end
end
