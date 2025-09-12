# This migration comes from fasp_client (originally 20250905153345)
class CreateFaspClientEventSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :fasp_client_event_subscriptions do |t|
      t.references :fasp_client_provider, null: false, foreign_key: true
      t.string :category
      t.string :subscription_type

      t.timestamps
    end
  end
end
