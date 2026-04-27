class AddPreviewFieldsToCollections < ActiveRecord::Migration[8.0]
  def change
    change_table :collections do |t|
      t.json :cover_data
      t.references :preview_model, foreign_key: {to_table: "models"}
    end
  end
end
