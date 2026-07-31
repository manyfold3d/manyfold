Sidekiq.configure_server do |config|
  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
  config.logger.level = Amiko.logger.level
end
