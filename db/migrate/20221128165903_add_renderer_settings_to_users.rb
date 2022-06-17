class AddRendererSettingsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :renderer_settings, :json, default: {grid_width: 200, grid_depth: 200}
  end
end
