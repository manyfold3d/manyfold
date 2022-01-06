class RemoveImagesTable < ActiveRecord::Migration[6.1]
  def change
    drop_table :images
  end
end
