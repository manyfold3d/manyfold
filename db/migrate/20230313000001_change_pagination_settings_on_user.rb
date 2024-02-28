class ChangePaginationSettingsOnUser < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :pagination_settings,
      from: {models: true, creators: true, per_page: 12},
      to: {models: true, creators: true, collections: true, per_page: 12}
  end
end
