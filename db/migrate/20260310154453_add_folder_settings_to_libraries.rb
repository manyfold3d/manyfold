class AddFolderSettingsToLibraries < ActiveRecord::Migration[8.0]
  def change
    add_column :libraries, :path_template, :string, null: false, default: "{tags}/{modelName}{modelId}"
    add_column :libraries, :parse_metadata_from_path, :boolean, default: false, null: false
    add_column :libraries, :safe_folder_names, :boolean, default: true, null: false
  end
end
