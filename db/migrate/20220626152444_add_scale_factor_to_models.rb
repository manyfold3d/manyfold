class AddScaleFactorToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :scale_factor, :decimal, null: false, default: 100.0
  end
end
