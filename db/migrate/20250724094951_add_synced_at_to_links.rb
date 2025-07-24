class AddSyncedAtToLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :links, :synced_at, :datetime
  end
end
