Rails.application.config.after_initialize do
  Rails.cache.delete_matched("FileHandlers_handlers_for_*")
rescue RedisClient::CannotConnectError
end
