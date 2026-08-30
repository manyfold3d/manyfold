# frozen_string_literal: true

# INIT-013/SPEC-002 — SCAN-only prune of RP Redis keys (ADR D-6 / REQ-005).
# Dry-run is the default; mutate deletes orphans (no TTL) and deny-listed worker keys.
module Performance
  class Prune
    ALL_MATCH = "*"

    Result = Data.define(:would_delete, :keep, :errors, :deleted, :budget_exceeded, :dry_run)

    def initialize(redis: nil, dry_run: true,
      scan_count: Performance::RedisScan::DEFAULT_COUNT,
      max_iterations: Performance::RedisScan::DEFAULT_MAX_ITERATIONS)
      @redis = redis
      @dry_run = dry_run
      @scan_count = scan_count
      @max_iterations = max_iterations
    end

    def call
      client = redis_client
      if client.nil?
        return Result.new(
          would_delete: 0, keep: 0, errors: ["redis_unavailable"],
          deleted: 0, budget_exceeded: false, dry_run: @dry_run
        )
      end

      scan = Performance::RedisScan.each_matching(
        client,
        match: ALL_MATCH,
        count: @scan_count,
        max_iterations: @max_iterations
      )

      would_delete = 0
      keep = 0
      errors = []
      deleted = 0
      to_delete = []

      scan.keys.each do |key|
        decision = classify(client, key)
        case decision
        when :delete
          would_delete += 1
          to_delete << key
        when :keep
          keep += 1
        when :error
          errors << key
        end
      end

      unless @dry_run
        to_delete.each do |key|
          client.del(key)
          deleted += 1
        rescue => e
          errors << "#{key}:#{e.class}"
        end
      end

      Result.new(
        would_delete: would_delete,
        keep: keep,
        errors: errors,
        deleted: deleted,
        budget_exceeded: scan.budget_exceeded,
        dry_run: @dry_run
      )
    end

    private

    def redis_client
      @redis || (defined?(RailsPerformance) && RailsPerformance.redis)
    end

    def classify(client, key)
      return :delete if deny_listed_worker_key?(key)

      ttl = client.ttl(key)
      # -2 gone; -1 no expire (orphan); 0 rare edge — treat as deletable retention noise
      if ttl == -1 || ttl == 0
        :delete
      elsif ttl == -2
        :error
      else
        :keep
      end
    rescue => e
      Rails.logger.warn("[Performance::Prune] classify failed for #{key}: #{e.class}") if defined?(Rails)
      :error
    end

    def deny_listed_worker_key?(key)
      Performance::SkippedWorkers::NAMES.any? do |name|
        key.include?("|worker|#{name}|")
      end
    end
  end
end
