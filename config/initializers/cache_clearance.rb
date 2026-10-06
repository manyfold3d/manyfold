Rails.application.config.after_initialize do
  Rails.cache.delete_matched("FileHandlers_handlers_for_*") if ENV["RAILS_ASSETS_PRECOMPILE"].blank?
rescue RedisClient::CannotConnectError
end
