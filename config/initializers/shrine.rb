require "shrine"
require "shrine/storage/file_system"

Shrine.plugin :activerecord
Shrine.plugin :refresh_metadata
Shrine.plugin :determine_mime_type
Shrine.plugin :rack_response

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("tmp/cache")
}

Rails.application.config.after_initialize do
  Library.register_all_storage
end
