class AddNotesExcerptToModelFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :model_files, :notes, :text
    add_column :model_files, :excerpt, :text
  end
end
