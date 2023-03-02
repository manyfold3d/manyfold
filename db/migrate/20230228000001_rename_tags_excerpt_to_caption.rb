class RenameTagsExcerptToCaption < ActiveRecord::Migration[7.0]
  def change
    rename_column :tags, :excerpt, :caption
  end
end
