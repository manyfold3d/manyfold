class AddMissingUniqueIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :libraries, :path, unique: true
    add_index :models, [:path, :library_id], unique: true
    add_index :model_files, [:filename, :model_id], unique: true
    add_index :problems, [:category, :problematic_id, :problematic_type], unique: true,
      name: "index_problems_on_category_and_problematic_id_and_type"
  end
end
