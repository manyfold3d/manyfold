class AddPublicIDsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.string :public_id
      t.index :public_id
    end
  end
end
