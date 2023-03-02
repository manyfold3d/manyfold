class AddNotesExcerptToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :notes, :text
    add_column :tags, :excerpt, :text
  end
end
