class AddPaginationSettingsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :pagination_settings, :json, default: {models: true, creators: true, per_page: 12}
  end
end
