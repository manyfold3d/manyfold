if defined?(RailsPerformance) && !Rails.env.test?
  RailsPerformance.setup do |config|
    config.redis = Redis::Namespace.new("#{Rails.env}-rails-performance", redis: Redis.new)
    config.duration = 4.hours

    config.enabled = true

    config.ignored_paths = ["/admin", "/health"]

    # configure Recent tab (time window and limit of requests)
    config.recent_requests_time_window = 60.minutes
    # config.recent_requests_limit = nil # or 1000

    # configure Slow Requests tab (time window, limit of requests and threshold)
    config.slow_requests_time_window = 60.minutes
    # config.slow_requests_limit = 500 # number of max rows
    # config.slow_requests_threshold = 500 # number of ms

    # store custom data for the request
    config.custom_data_proc = proc do |env|
      {
        pid: Process.pid,
        memory_usage: GetProcessMem.new.bytes
      }
    end

    # config home button link
    config.home_link = "/"

    # To skip some Rake tasks from monitoring
    config.skipable_rake_tasks = ["webpacker:compile"]

    # To monitor rake tasks performance, you need to include rake tasks
    # config.include_rake_tasks = false

    # To monitor custom events with `RailsPerformance.measure` block
    # config.include_custom_events = true
  end
end
