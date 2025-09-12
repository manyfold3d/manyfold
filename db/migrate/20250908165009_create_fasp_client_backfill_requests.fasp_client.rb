# This migration comes from fasp_client (originally 20250908164011)
class CreateFaspClientBackfillRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :fasp_client_backfill_requests do |t|
      t.references :fasp_client_provider, null: false, foreign_key: true
      t.string :category
      t.integer :max_count

      t.timestamps
    end
  end
end
