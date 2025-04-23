class AddLowercaseFilenameVirtualFieldToModelFiles < ActiveRecord::Migration[8.0]
  def change
    add_column :model_files, :filename_lower, :virtual, type: :string, as: "LOWER(filename)", stored: true
    add_index :model_files, :filename_lower
  end
end
