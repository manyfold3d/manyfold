class AddQuotaToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :quota, :integer, null: true
    add_column :users, :quota_use_site_default, :boolean, default: true, null: false
  end
end
