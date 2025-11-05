class AddSortOrderToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sort_order, :integer, default: 0, null: false
  end
end
