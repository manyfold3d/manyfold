require "tus/server"
require "tus/storage/filesystem"

Rails.application.config.after_initialize do
  Library.register_all_storage

  Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new("tmp/shrine")
  Tus::Server.opts[:max_size] = SiteSettings.max_file_upload_size

  begin
    upload_options = {cache: {move: true}}
    Library.all.map do |l|
      upload_options[l.storage_key] = {move: true} if l.storage_service == "filesystem"
    end
    ModelFileUploader.plugin :upload_options, **upload_options unless Rails.env.test?
  rescue ActiveRecord::StatementInvalid, NameError
    nil # migrations probably haven't run yet to create library table
  end

  begin
    Sidekiq::Cron::Job.create(
      name: "clear-shrine-cache",
      cron: "every hour",
      class: "CacheSweepJob"
    )
    Sidekiq::Cron::Job.create(
      name: "clear-downloads",
      cron: "every hour",
      class: "DownloadsSweepJob"
    )
  rescue RedisClient::CannotConnectError
  end
end
