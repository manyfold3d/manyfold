# frozen_string_literal: true

# INIT-008/SPEC-002 — Printer capabilities for Settings identity / compatibility gate
class AddPrintHostCapabilities < ActiveRecord::Migration[8.0]
  def change
    change_table :print_hosts, bulk: true do |t|
      t.string :brand
      t.string :machine_model
      t.string :firmware
      t.string :mac_address
      t.integer :resolution_w
      t.integer :resolution_h
      t.decimal :build_x_mm, precision: 8, scale: 2
      t.decimal :build_y_mm, precision: 8, scale: 2
      t.decimal :build_z_mm, precision: 8, scale: 2
      t.json :native_formats, default: [], null: false
      t.integer :fep_cycles, default: 0, null: false
      t.decimal :lcd_hours, precision: 10, scale: 2, default: 0, null: false
      t.bigint :storage_bytes_used
      t.bigint :storage_bytes_total
    end
  end
end
