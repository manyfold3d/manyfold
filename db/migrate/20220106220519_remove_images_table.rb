class RemoveImagesTable < ActiveRecord::Migration[6.1]
  def change
    drop_table :images # rubocop:disable Rails/ReversibleMigration
  end
end
