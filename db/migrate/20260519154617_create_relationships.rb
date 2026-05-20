class CreateRelationships < ActiveRecord::Migration[8.0]
  def change
    create_table :relationships do |t|
      t.references :subject, polymorphic: true, null: false
      t.references :objekt, polymorphic: true, null: false
      t.string :predicate
      t.timestamps
      t.index [:subject_id, :subject_type, :objekt_id, :objekt_type, :predicate], unique: true
      t.index [:subject_id, :subject_type, :predicate]
      t.index [:objekt_id, :objekt_type, :predicate]
    end
  end
end
