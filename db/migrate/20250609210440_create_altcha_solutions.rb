class CreateAltchaSolutions < ActiveRecord::Migration[8.0]
  def change
    create_table(:altcha_solutions) do |t|
      t.string :algorithm
      t.string :challenge
      t.string :salt
      t.string :signature
      t.integer :number

      t.timestamps
    end

    add_index :altcha_solutions, [:algorithm, :challenge, :salt, :signature, :number], unique: true, name: "index_altcha_solutions"
  end
end
