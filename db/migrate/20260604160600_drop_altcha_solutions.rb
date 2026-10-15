class DropAltchaSolutions < ActiveRecord::Migration[8.0]
  def up
    drop_table :altcha_solutions
  end

  def down
    create_table :altcha_solutions do |t|
      t.string :algorithm
      t.string :challenge
      t.string :salt
      t.string :signature
      t.integer :number

      t.timestamps
    end
  end
end
