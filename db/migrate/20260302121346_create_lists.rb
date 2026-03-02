class CreateLists < ActiveRecord::Migration[8.0]
  def change
    create_table :lists do |t|
      t.string :name
      t.timestamps
    end

    create_table :list_items do |t|
      t.belongs_to :list, null: false, foreign_key: true
      t.references :listable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
