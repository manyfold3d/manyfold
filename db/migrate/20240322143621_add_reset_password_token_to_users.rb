class AddResetPasswordTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    # This migration adds "reset_password_token" without the rest of devise/recoverable
    # because we want to use it for admin setup, before adding full recovery capability.
    add_column :users, :reset_password_token, :string
    add_index :users, :reset_password_token, unique: true
  end
end
