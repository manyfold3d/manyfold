class AddSizeToModelFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :model_files, :size, :integer
  end
end
