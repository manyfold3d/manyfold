require "shrine"
require "shrine/storage/file_system"

Shrine.plugin :activerecord
Shrine.plugin :refresh_metadata
Shrine.plugin :determine_mime_type

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("tmp/cache")
}

Rails.application.config.after_initialize do
  Library.find_each(&:register_storage)
rescue ActiveRecord::StatementInvalid
  nil # migrations probably haven't run yet to create library table
end
