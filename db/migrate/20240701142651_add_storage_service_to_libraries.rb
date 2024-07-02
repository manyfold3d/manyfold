class AddStorageServiceToLibraries < ActiveRecord::Migration[7.1]
  def change
    add_column :libraries, :storage_service, :string, null: false, default: "filesystem"
  end
end
