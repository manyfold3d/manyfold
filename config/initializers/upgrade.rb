Rails.application.config.after_initialize do
  Upgrade::FixNilFileSizeValues.set(queue: :upgrade).perform_async
rescue RedisClient::CannotConnectError
end
