Rails.application.config.after_initialize do
  # Attempt to connect to Redis first before queueing, and fail early
  Sidekiq.redis { |conn| conn.info }
  # Queue upgrade jobs if Redis is good to go
  Upgrade::FixNilFileSizeValues.set(queue: :upgrade).perform_later
  Upgrade::BackfillDataPackages.set(queue: :upgrade).perform_later
  Upgrade::DisambiguateUsernamesJob.set(queue: :upgrade).perform_later
  Upgrade::UpdateActorsJob.set(queue: :upgrade).perform_later
rescue RedisClient::CannotConnectError
end
