class AddFieldsToParts < ActiveRecord::Migration[6.1]
  def change
    add_column :parts, :presupported, :boolean, default: false
    add_column :parts, :printed, :boolean, default: false
  end
end
