class AddTagCloudSettingsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :tag_cloud_settings, :json
  end
end
