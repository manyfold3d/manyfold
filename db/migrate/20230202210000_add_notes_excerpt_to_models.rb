class AddNotesExcerptToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :notes, :text
    add_column :models, :excerpt, :text
  end
end
