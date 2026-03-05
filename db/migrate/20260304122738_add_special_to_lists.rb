class AddSpecialToLists < ActiveRecord::Migration[8.0]
  def change
    add_column :lists, :special, :string
  end
end
