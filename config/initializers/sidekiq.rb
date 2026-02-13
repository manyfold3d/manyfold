Sidekiq.configure_server do |config|
  config.logger.level = Rails.logger.level
end
