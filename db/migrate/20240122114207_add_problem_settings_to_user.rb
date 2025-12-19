class AddProblemSettingsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :problem_settings, :json
  end
end
