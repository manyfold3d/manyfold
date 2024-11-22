class AddApprovedToUser < ActiveRecord::Migration[7.2]
  def change
    change_table :users do |t|
      t.boolean :approved, default: true, null: false
      t.index :approved
    end
  end
end
