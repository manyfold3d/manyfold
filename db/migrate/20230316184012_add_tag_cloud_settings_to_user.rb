class AddTagCloudSettingsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :tag_cloud_settings, :json, default: {
      threshold: 0,
      heatmap: true,
      keypair: true,
      sorting: "frequency",
      hide_unrelated: true
    }
  end
end
