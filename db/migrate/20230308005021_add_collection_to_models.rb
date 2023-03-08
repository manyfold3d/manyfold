class AddCollectionToModels < ActiveRecord::Migration[7.0]
  def change
    add_reference :models, :collection, null: true, foreign_key: true
  end
end
