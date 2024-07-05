class ChangeIndexOnLibraryPath < ActiveRecord::Migration[7.1]
  def up
    remove_index :libraries, :path
  end

  def down
    add_index :libraries, :path, unique: true
  end
end
