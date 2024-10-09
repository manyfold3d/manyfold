class AddSystemToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :system, :boolean, null: false, default: false
  end
end
