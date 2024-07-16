class AddFileListSettingsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :file_list_settings, :json, default: SiteSettings::UserDefaults::FILE_LIST
  end
end
