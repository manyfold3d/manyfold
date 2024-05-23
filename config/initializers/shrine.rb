require "shrine"
require "shrine/storage/file_system"

Shrine.plugin :activerecord

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("tmp/cache")
}

Rails.application.config.after_initialize do
  Library.find_each(&:register_storage)
end
