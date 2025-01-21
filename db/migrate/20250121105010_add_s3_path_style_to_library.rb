class AddS3PathStyleToLibrary < ActiveRecord::Migration[7.2]
  def change
    add_column :libraries, :s3_path_style, :boolean, default: true, null: false
  end
end
