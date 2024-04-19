# Sidekiq and Rails communicate via redis, so we should always use that.
ActiveJob::Status.store = :redis_cache_store, {url: ENV.fetch("REDIS_URL", nil)}

ActiveJob::Status.options = {
  includes: %i[status serialized_job exception],
  expires_in: 24.hours.to_i
}

module ActiveJob::Status
  def self.all
    store.redis.keys("activejob:status:*").map { |x| ActiveJob::Status.get(x.split(":").last) }
  end
end

class ActiveJob::Status::Status
  def last_activity
    [
      self[:serialized_job]["enqueued_at"],
      self[:started_at],
      self[:finished_at]
    ].compact.max
  end
end
