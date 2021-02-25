class CreateCreators < ActiveRecord::Migration[6.1]
  def change
    create_table :creators do |t|
      t.string :name, null: false
      t.string :thingiverse_user
      t.string :cults3d_user
      t.string :mmf_user
      t.string :cgtrader_user
      t.timestamps
    end
  end
end
