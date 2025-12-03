class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.belongs_to :creator, null: false, foreign_key: true

      t.timestamps
    end

    create_join_table :groups, :users, table_name: "memberships" do |t|
      t.index [:group_id, :user_id]
      t.index [:user_id, :group_id]
    end
  end
end
