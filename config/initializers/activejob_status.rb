# Sidekiq and Rails communicate via redis, so we should always use that.
ActiveJob::Status.store = :redis_cache_store, { url: ENV.fetch("REDIS_URL") }

