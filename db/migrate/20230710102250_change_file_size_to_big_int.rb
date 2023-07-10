class ChangeFileSizeToBigInt < ActiveRecord::Migration[7.0]
  def up
    change_column :model_files, :size, :bigint
  end

  def down
    change_column :model_files, :size, :integer
  end
end
