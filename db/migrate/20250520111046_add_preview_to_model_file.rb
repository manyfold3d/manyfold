class AddPreviewToModelFile < ActiveRecord::Migration[8.0]
  def change
    add_column :model_files, :previewable, :boolean, default: false, null: false
  end
end
