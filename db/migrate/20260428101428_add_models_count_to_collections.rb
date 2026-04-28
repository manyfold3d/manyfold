class AddModelsCountToCollections < ActiveRecord::Migration[8.0]
  def self.up
    add_column :collections_models, :id, :primary_key # rubocop:disable Rails/DangerousColumnNames
    add_column :collections, :models_count, :integer
  end

  def self.down
    remove_column :collections, :models_count
    remove_column :collections_models, :id
  end
end
