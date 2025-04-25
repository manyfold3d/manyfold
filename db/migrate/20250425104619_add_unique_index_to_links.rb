class AddUniqueIndexToLinks < ActiveRecord::Migration[8.0]
  def change
    add_index :links, [:linkable_id, :linkable_type, :url]
  end
end
