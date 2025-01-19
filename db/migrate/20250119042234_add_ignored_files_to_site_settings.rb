class AddIgnoredFilesToSiteSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :site_settings, :ignored_files, :text
  end
end
