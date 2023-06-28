class AddUniqueConstraintToNamesAndSlugs < ActiveRecord::Migration[7.0]
  def change
    add_index :creators, :name, unique: true
    remove_index :creators, :slug
    add_index :creators, :slug, unique: true
    add_index :collections, :name, unique: true
    remove_index :collections, :slug
    add_index :collections, :slug, unique: true
  end
end
