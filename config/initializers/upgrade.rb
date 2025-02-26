Rails.application.config.after_initialize do
  Upgrade::FixNilFileSizeValues.set(queue: :upgrade).perform_async
  Upgrade::BackfillDataPackages.set(queue: :upgrade).perform_later
rescue RedisClient::CannotConnectError
end
