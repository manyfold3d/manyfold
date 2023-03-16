class CreateCollection < ActiveRecord::Migration[7.0]
  def change
    create_table :collections do |t|
      t.string :name
      t.text :notes
      t.text :excerpt

      t.timestamps
    end
  end
end
