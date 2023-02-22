class RenameExcerptToCaption < ActiveRecord::Migration[7.0]
  def change
    rename_column :creators, :excerpt, :caption
    rename_column :models, :excerpt, :caption
    rename_column :model_files, :excerpt, :caption
  end
end
