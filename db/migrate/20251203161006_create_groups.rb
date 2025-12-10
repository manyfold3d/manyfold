class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.belongs_to :creator, null: false, foreign_key: true
      t.timestamps
    end

    # Use standard table instead of create_join_table
    # otherwise no id is generated that will support accepts_nested_attributes_for
    # See https://github.com/rails/rails/issues/48714 and https://github.com/rails/rails/pull/48733
    create_table :memberships do |t|
      t.belongs_to :group
      t.belongs_to :user
      t.timestamps
      t.index [:group_id, :user_id]
      t.index [:user_id, :group_id]
    end
  end
end
