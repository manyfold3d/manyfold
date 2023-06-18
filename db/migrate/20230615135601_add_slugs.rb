class AddSlugs < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :slug, :string
    add_index :models, :slug
    add_column :collections, :slug, :string
    add_index :collections, :slug
    add_column :creators, :slug, :string
    add_index :creators, :slug
  end
end
