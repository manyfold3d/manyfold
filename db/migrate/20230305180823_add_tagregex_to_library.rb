class AddTagregexToLibrary < ActiveRecord::Migration[7.0]
  def change
    add_column :libraries, :tag_regex, :text
  end
end
