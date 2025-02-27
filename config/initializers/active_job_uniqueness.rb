# frozen_string_literal: true

ActiveJob::Uniqueness.configure do |config|
  # Global default expiration for lock keys. Each job can define its own ttl via :lock_ttl option.
  # Strategy :until_and_while_executing also accepts :on_runtime_ttl option.
  #
  # config.lock_ttl = 1.day

  # Prefix for lock keys. Can not be set per job.
  #
  # config.lock_prefix = 'activejob_uniqueness'

  # Default action on lock conflict. Can be set per job.
  # Strategy :until_and_while_executing also accepts :on_runtime_conflict option.
  # Allowed values are
  #   :raise - raises ActiveJob::Uniqueness::JobNotUnique
  #   :log - instruments ActiveSupport::Notifications and logs event to the ActiveJob::Logger
  #   proc - custom Proc. For example, ->(job) { job.logger.info("Job already in queue: #{job.class.name} #{job.arguments.inspect} (#{job.job_id})") }
  #
  config.on_conflict = :log

  # Default action on redis connection error. Can be set per job.
  # Allowed values are
  #   :raise - raises ActiveJob::Uniqueness::JobNotUnique
  #   proc - custom Proc. For example, ->(job, resource: _, error: _) { job.logger.info("Job already in queue: #{job.class.name} #{job.arguments.inspect} (#{job.job_id})") }
  #
  # config.on_redis_connection_error = :raise

  # Digest method for lock keys generating. Expected to have `hexdigest` class method.
  #
  # config.digest_method = OpenSSL::Digest::MD5

  # Array of redis servers for Redlock quorum.
  # Read more at https://github.com/leandromoreira/redlock-rb#redis-client-configuration
  #
  # config.redlock_servers = [ENV.fetch('REDIS_URL', 'redis://localhost:6379')]

  # Custom options for Redlock.
  # Read more at https://github.com/leandromoreira/redlock-rb#redlock-configuration
  #
  # config.redlock_options = { retry_count: 0 }

  # Custom strategies.
  # config.lock_strategies = { my_strategy: MyStrategy }
  #
  # config.lock_strategies = {}
end
