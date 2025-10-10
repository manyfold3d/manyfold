# This migration comes from federails (originally 20250426061729)
class CreateFederailsHosts < ActiveRecord::Migration[7.2]
  def change
    create_table :federails_hosts do |t|
      t.string :domain, null: false, default: nil
      t.string :nodeinfo_url
      t.string :software_name
      t.string :software_version

      # Uncomment the lines below if you use PostgreSQL
      # t.jsonb :protocols, default: []
      # t.jsonb :services, default: {}
      #
      # Other databases
      t.text :protocols, default: "[]"
      t.text :services, default: "{}"

      t.timestamps

      t.index :domain, unique: true
    end
  end
end
