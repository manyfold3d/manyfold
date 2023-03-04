class AddNotesNameCaptionToLibrary < ActiveRecord::Migration[7.0]
  def change
    add_column :libraries, :notes, :string
    add_column :libraries, :caption, :string
    add_column :libraries, :name, :string
  end
end
