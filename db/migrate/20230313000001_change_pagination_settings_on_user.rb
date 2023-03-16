class ChangePaginationSettingsOnUser < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :pagination_settings, :json, default: {models: true, creators: true, collections: true, per_page: 12}
  end
end
