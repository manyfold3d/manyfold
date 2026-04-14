class AddLikeCountToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :models, :like_count, :integer, default: 0, null: false
  end
end
