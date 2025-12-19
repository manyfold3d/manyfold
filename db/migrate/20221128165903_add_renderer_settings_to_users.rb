class AddRendererSettingsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :renderer_settings, :json
  end
end
