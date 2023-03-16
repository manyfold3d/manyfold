class RenameCollectionExcerptToCaption < ActiveRecord::Migration[7.0]
  def change
    rename_column :collections, :excerpt, :caption
  end
end
