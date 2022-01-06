class RenamePartsToModelFiles < ActiveRecord::Migration[6.1]
  def change
    rename_table :parts, :model_files
    rename_column :models, :preview_part_id, :preview_file_id
  end
end
