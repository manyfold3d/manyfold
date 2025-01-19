class AddIgnoredFilesToSiteSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :site_settings, :ignored_files, :text, null: true, default: [
      /^\.[^\.]+/, # Hidden files starting with .
      /.*\/@eaDir\/.*/, # Synology temp files
      /__MACOSX/ # MACOS resource forks
    ]
  end
end
