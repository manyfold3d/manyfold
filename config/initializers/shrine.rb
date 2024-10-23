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
    Sidekiq::Cron::Job.create(
      name: "clear-shrine-cache",
      cron: "every hour",
      class: "CacheSweepJob"
    )
  rescue RedisClient::CannotConnectError
  end
end
