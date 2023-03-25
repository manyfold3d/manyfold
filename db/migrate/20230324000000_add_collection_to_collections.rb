class AddCollectionToCollections < ActiveRecord::Migration[7.0]
  def change
    add_reference :collections, :collection, null: true, foreign_key: true
  end
end
