class CreateUniqueIndexesOnGroups < ActiveRecord::Migration[8.0]
  def change
    remove_index :memberships, [:group_id, :user_id]
    add_index :memberships, [:group_id, :user_id], unique: true
    remove_index :memberships, [:user_id, :group_id]
    add_index :memberships, [:user_id, :group_id], unique: true
  end
end
