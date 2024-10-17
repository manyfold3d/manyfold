class AddSensitiveFlagToModelsAndComments < ActiveRecord::Migration[7.1]
  def change
    [:models, :comments].each do |table|
      add_column table, :sensitive, :boolean, null: false, default: false
    end
  end
end
