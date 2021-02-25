class AddCreatorToModels < ActiveRecord::Migration[6.1]
  def change
    add_reference :models, :creator, null: true, foreign_key: true
  end
end
