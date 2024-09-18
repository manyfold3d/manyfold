Rails.application.config.after_initialize do
  Library.register_all_storage

  begin
    upload_options = {cache: {move: true}}
    Library.all.map do |l|
      upload_options[l.storage_key] = {move: true} if l.storage_service == "filesystem"
    end
    LibraryUploader.plugin :upload_options, **upload_options unless Rails.env.test?
  rescue ActiveRecord::StatementInvalid, NameError
    nil # migrations probably haven't run yet to create library table
  end

  begin
    Sidekiq.set_schedule("sweep", {every: "1h", class: "CacheSweepJob"})
  rescue RedisClient::CannotConnectError
  end
end
