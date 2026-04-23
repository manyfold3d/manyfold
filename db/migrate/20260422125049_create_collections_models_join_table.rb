class CreateCollectionsModelsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :collections, :models
  end
end
