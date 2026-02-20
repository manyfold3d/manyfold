class AddFlatFolderScanningToLibraries < ActiveRecord::Migration[8.0]
  def change
    add_column :libraries, :flat_folder_scanning, :boolean, default: false, null: false
  end
end
