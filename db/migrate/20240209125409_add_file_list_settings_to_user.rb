class AddFileListSettingsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :file_list_settings, :json, default: {
      hide_presupported_versions: true
    }
  end
end
