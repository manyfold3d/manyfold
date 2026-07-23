# frozen_string_literal: true

class ActsAsFavoritorMigration < ActiveRecord::Migration[7.0]
  def self.up
    create_table :favorites, force: true do |t|
      # Default references field has no limit on the type string length, which causes
      # MySQL problems. See https://github.com/jonhue/acts_as_favoritor/discussions/238#discussioncomment-1629078
      # t.references :favoritable, polymorphic: true, null: false
      # t.references :favoritor, polymorphic: true, null: false

      # So instead, we add fields explicitly with a sensible string length limit
      # for MySQL index length compatibility
      t.integer :favoritor_id, null: false
      t.string :favoritor_type, null: false, limit: 50
      t.index [:favoritor_type, :favoritor_id], name: "index_favorites_on_favoritor"
      t.integer :favoritable_id, null: false
      t.string :favoritable_type, null: false, limit: 50
      t.index [:favoritable_type, :favoritable_id], name: "index_favorites_on_favoritable"

      t.string :scope, default: ActsAsFavoritor.configuration.default_scope,
        null: false,
        index: true
      t.boolean :blocked, default: false, null: false, index: true
      t.timestamps
    end

    add_index :favorites,
      ["favoritor_id", "favoritor_type"],
      name: "fk_favorites"
    add_index :favorites,
      ["favoritable_id", "favoritable_type"],
      name: "fk_favoritables"
    add_index :favorites,
      ["favoritable_type", "favoritable_id", "favoritor_type",
        "favoritor_id", "scope"],
      name: "uniq_favorites__and_favoritables", unique: true
  end

  def self.down
    drop_table :favorites
  end
end
