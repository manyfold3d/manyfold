class AddOmniauthToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :auth_provider, :string
    add_column :users, :auth_uid, :string
  end
end
