class AddYUpToParts < ActiveRecord::Migration[6.1]
  def change
    add_column :parts, :y_up, :boolean, default: false, null: false
  end
end
