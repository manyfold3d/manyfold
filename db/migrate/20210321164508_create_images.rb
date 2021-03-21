class CreateImages < ActiveRecord::Migration[6.1]
  def change
    create_table :images do |t|
      t.references :model, null: false, foreign_key: true
      t.string :filename
      t.timestamps
    end
  end
end
