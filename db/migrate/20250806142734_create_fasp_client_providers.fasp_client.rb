# This migration comes from fasp_client (originally 20250801150509)
class CreateFaspClientProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :fasp_client_providers do |t|
      t.string :uuid
      t.string :name
      t.string :base_url
      t.string :server_id
      t.string :public_key
      t.string :ed25519_signing_key
      t.integer :status
      t.json :capabilities
      t.json :privacy_policy
      t.string :sign_in_url
      t.string :contact_email
      t.string :fediverse_account
      t.timestamps
    end
  end
end
