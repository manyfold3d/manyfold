class AddOrderIndexesToTables < ActiveRecord::Migration[8.0]
  def change
    [:models, :creators, :collections].each do |table|
      change_table table do |t|
        t.index :created_at
        t.index :updated_at
      end
    end
  end
end
