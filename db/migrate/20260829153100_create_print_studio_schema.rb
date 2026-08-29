# frozen_string_literal: true

# INIT-008/SPEC-002 — Print jobs, artifacts, consumables, curation notes
class CreatePrintStudioSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :sliced_artifacts do |t|
      t.references :model, null: false, foreign_key: true
      t.references :print_host, null: false, foreign_key: true
      t.references :model_file, null: true, foreign_key: true
      t.string :format, null: false
      t.integer :estimated_layers
      t.integer :estimated_duration_seconds
      t.decimal :estimated_resin_ml, precision: 10, scale: 2

      t.timestamps
    end
    add_index :sliced_artifacts, [:model_id, :print_host_id]

    create_table :print_jobs do |t|
      t.references :print_host, null: false, foreign_key: true
      t.references :model, null: true, foreign_key: true
      t.references :model_file, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.references :sliced_artifact, null: true, foreign_key: true
      t.string :state, null: false, default: "queued"
      t.datetime :plate_cleared_at
      t.string :resin_profile
      t.integer :layer_count
      t.integer :current_layer
      t.integer :estimated_duration_seconds
      t.integer :actual_duration_seconds
      t.decimal :estimated_resin_ml, precision: 10, scale: 2
      t.decimal :actual_resin_ml, precision: 10, scale: 2
      t.string :outcome
      t.text :failure_note
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
    add_index :print_jobs, :state
    add_index :print_jobs, [:print_host_id, :state]
    # At most one actively printing job per host (REQ-006)
    add_index :print_jobs, :print_host_id,
      unique: true,
      where: "state = 'printing'",
      name: "index_print_jobs_one_printing_per_host"

    create_table :resin_bottles do |t|
      t.string :brand, null: false
      t.string :color
      t.decimal :remaining_ml, precision: 10, scale: 2, null: false
      t.decimal :capacity_ml, precision: 10, scale: 2, null: false
      t.date :opened_on
      t.references :print_host, null: true, foreign_key: true

      t.timestamps
    end

    create_table :print_vats do |t|
      t.string :identity, null: false
      t.integer :fep_cycles, default: 0, null: false
      t.references :print_host, null: false, foreign_key: true
      t.references :resin_bottle, null: true, foreign_key: true
      t.string :status, null: false, default: "ready"

      t.timestamps
    end
    add_index :print_vats, [:print_host_id, :identity], unique: true

    create_table :print_curation_notes do |t|
      t.references :model, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.text :body

      t.timestamps
    end
  end
end
