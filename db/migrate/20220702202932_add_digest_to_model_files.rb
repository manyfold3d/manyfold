class AddDigestToModelFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :model_files, :digest, :string
    add_index :model_files, :digest
  end
end
