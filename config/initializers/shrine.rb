require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/s3"

Shrine.plugin :activerecord
Shrine.plugin :refresh_metadata
Shrine.plugin :determine_mime_type
Shrine.plugin :rack_response

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("tmp/shrine")
}

Rails.application.config.after_initialize do
  Library.register_all_storage

  begin
    upload_options = {cache: {move: true}}
    Library.all.map do |l|
      upload_options[l.storage_key.to_sym] = {move: true} if l.storage_service == "filesystem"
    end
    Shrine.plugin :upload_options, **upload_options unless Rails.env.test?
  rescue ActiveRecord::StatementInvalid, NameError
    nil # migrations probably haven't run yet to create library table
  end

  begin
    Sidekiq.set_schedule("sweep", {every: "1h", class: "CacheSweepJob"})
  rescue RedisClient::CannotConnectError
  end
end
