class RemoveScaleFactorFromModels < ActiveRecord::Migration[7.0]
  def change
    remove_column :models, :scale_factor, :decimal, default: "100.0", null: false
  end
end
