class CreateCaberRelations < ActiveRecord::Migration[7.1]
  def change
    create_table :caber_relations do |t|
      t.references :subject, polymorphic: true, null: true
      t.string :permission
      t.references :object, polymorphic: true, null: false

      t.timestamps
      t.index [:subject_id, :subject_type, :object_id, :object_type], unique: true
    end
  end
end
