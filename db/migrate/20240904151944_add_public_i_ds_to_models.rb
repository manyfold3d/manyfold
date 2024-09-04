class AddPublicIDsToModels < ActiveRecord::Migration[7.1]
  def change
    [:models, :model_files, :problems, :creators, :collections, :libraries].each do |table|
      add_column table, :public_id, :string
      add_index table, :public_id
    end
  end
end
