class AddQuotaToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :quota, :integer, default: 0
    add_column :users, :quota_use_site_default, :boolean, default: true
  end
end
