# frozen_string_literal: true

# INIT-013/SPEC-002 — bounded SCAN only (never KEYS). ADR D-4 / D-6.
module Performance
  module RedisScan
    # COUNT is a Redis hint; production RP namespaces (~80k+ keys) need headroom so
    # MATCH scans finish before max_iterations (ADR D-4 / REQ-002 KPI shell).
    DEFAULT_COUNT = 500
    DEFAULT_MAX_ITERATIONS = 2_500

    Result = Data.define(:keys, :budget_exceeded)

    module_function

    # Enumerate keys with Redis SCAN. Raises if +redis.keys+ is invoked by the client
    # (guarded in specs via fakes). Caps iterations so a request never walks the world.
    def each_matching(redis, match:, count: DEFAULT_COUNT, max_iterations: DEFAULT_MAX_ITERATIONS)
      raise ArgumentError, "redis is required" if redis.nil?

      cursor = "0"
      iterations = 0
      found = []
      budget_exceeded = false

      loop do
        iterations += 1
        if iterations > max_iterations
          budget_exceeded = true
          break
        end

        cursor, batch = redis.scan(cursor, match: match, count: count)
        found.concat(Array(batch))
        break if cursor.to_s == "0"
      end

      Result.new(keys: found, budget_exceeded: budget_exceeded)
    end
  end
end
