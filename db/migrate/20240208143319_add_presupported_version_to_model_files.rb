class AddPresupportedVersionToModelFiles < ActiveRecord::Migration[7.0]
  def change
    add_reference :model_files, :presupported_version, foreign_key: {to_table: :model_files}
  end
end
