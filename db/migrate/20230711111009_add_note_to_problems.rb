class AddNoteToProblems < ActiveRecord::Migration[7.0]
  def change
    add_column :problems, :note, :string, default: nil
  end
end
