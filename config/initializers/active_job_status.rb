# Sidekiq and Rails communicate via redis, so we should always use that.
ActiveJob::Status.store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL", nil),
  pool: {
    size: ActiveRecord::Base.connection_pool.size
  }
}

ActiveJob::Status.options = {
  includes: %i[status serialized_job exception],
  expires_in: 24.hours.to_i
}

module ActiveJob::Status
  def self.all
    store.redis.with do |conn|
      conn.keys("activejob:status:*").map { |it| ActiveJob::Status.get(it.split(":").last) }
    end
  end
end

class ActiveJob::Status::Status
  def last_activity
    [
      read.dig(:serialized_job, "enqueued_at"),
      read[:started_at],
      read[:finished_at]
    ].compact.max
  end
end
