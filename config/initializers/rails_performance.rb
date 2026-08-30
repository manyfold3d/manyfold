# frozen_string_literal: true

# INIT-013/SPEC-002 — rails_performance collector config + Sidekiq write-path skip (ADR D-5).
#
# Deny-listed Sidekiq workers (never written to RP Redis):
#   - Turbo::Streams::BroadcastStreamJob  (high-churn stream fan-out; not HTTP latency)
# See Performance::SkippedWorkers::NAMES — primary fix is write-path skip, not read filtering.
#
# Skip constants + SidekiqExt prepend: defer until after_initialize so Zeitwerk can
# resolve Performance::* during boot. Never touch during assets:precompile (Docker
# build sets RAILS_ASSETS_PRECOMPILE=1 and would NameError on early constant access).

Rails.application.config.after_initialize do
  next if ENV["RAILS_ASSETS_PRECOMPILE"].present?

  Performance::SidekiqExtSkip.install! if defined?(RailsPerformance)
end

if defined?(RailsPerformance) && !Rails.env.test? && ENV["RAILS_ASSETS_PRECOMPILE"].blank?
  RailsPerformance.setup do |config|
    redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
    config.redis = Redis::Namespace.new("#{Rails.env}-rails-performance", redis: Redis.new(url: redis_url))
    # Retention window (ADR D-6). Skip + prune reduce Sidekiq spam; do not lengthen for chatter.
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
    # config.custom_data_proc = proc do |env|
    # end

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
