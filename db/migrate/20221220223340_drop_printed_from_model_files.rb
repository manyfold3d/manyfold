class DropPrintedFromModelFiles < ActiveRecord::Migration[7.0]
  def change
    remove_column :model_files, :printed, :boolean
  end
end
