class AddNotesExcerptToCreators < ActiveRecord::Migration[7.0]
  def change
    add_column :creators, :notes, :text
    add_column :creators, :excerpt, :text
  end
end
