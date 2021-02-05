class CreateModels < ActiveRecord::Migration[6.1]
  def change
    create_table :models do |t|
      t.string :name, null: false
      t.string :path, null: false
      t.references :library, null: false, foreign_key: true
      t.timestamps
    end
  end
end
