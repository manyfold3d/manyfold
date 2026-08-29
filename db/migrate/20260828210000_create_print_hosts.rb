# frozen_string_literal: true

class CreatePrintHosts < ActiveRecord::Migration[8.0]
  def change
    create_table :print_hosts do |t|
      t.string :name, null: false
      t.string :protocol, null: false
      t.string :endpoint, null: false
      t.string :credentials
      # SDCP motherboard id from UDP discover / attributes (e.g. d307202d8c1e0100)
      t.string :mainboard_id

      t.timestamps
    end

    add_index :print_hosts, :protocol
    add_index :print_hosts, :mainboard_id
  end
end
