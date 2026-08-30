# frozen_string_literal: true

# INIT-013/SPEC-002 — KPI / chart read path without Redis KEYS (ADR D-3 / D-4).
# Percentiles and throughput come from HTTP request samples only — never Sidekiq keys.
# INIT-013/SPEC-004 — response_series + avg_db_ms for dashboard charts / secondary stats.
module Performance
  class Telemetry
    REQUEST_MATCH = "performance|*"
    CACHE_TTL = 15.seconds

    Result = Data.define(
      :p50, :p95, :p99,
      :throughput,
      :response_series,
      :sample_count,
      :avg_db_ms,
      :budget_exceeded
    )

    def initialize(redis: nil, scan_count: Performance::RedisScan::DEFAULT_COUNT,
      max_iterations: Performance::RedisScan::DEFAULT_MAX_ITERATIONS,
      cache: true)
      @redis = redis
      @scan_count = scan_count
      @max_iterations = max_iterations
      @cache = cache
    end

    def call
      if @cache && defined?(Rails) && Rails.respond_to?(:cache)
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { compute }
      else
        compute
      end
    end

    private

    def compute
      client = redis_client
      return empty_result(budget_exceeded: false) if client.nil?

      scan = Performance::RedisScan.each_matching(
        client,
        match: REQUEST_MATCH,
        count: @scan_count,
        max_iterations: @max_iterations
      )

      samples = load_request_samples(client, scan.keys)
      durations = samples.filter_map { |s| s[:duration] }.select { |d| d.is_a?(Numeric) }
      db_runtimes = samples.filter_map { |s| s[:db_runtime] }.select { |d| d.is_a?(Numeric) }

      Result.new(
        p50: percentile(durations, 50),
        p95: percentile(durations, 95),
        p99: percentile(durations, 99),
        throughput: throughput_series(samples),
        response_series: response_time_series(samples),
        sample_count: samples.size,
        avg_db_ms: average(db_runtimes),
        budget_exceeded: scan.budget_exceeded
      )
    end

    def redis_client
      @redis || (defined?(RailsPerformance) && RailsPerformance.redis)
    end

    def load_request_samples(client, keys)
      return [] if keys.empty?

      values = client.mget(*keys)
      keys.zip(values).filter_map do |key, raw|
        next if raw.blank?

        parsed = parse_json(raw)
        {
          duration: parsed["duration"],
          db_runtime: parsed["db_runtime"],
          datetime: datetime_from_key(key),
          datetimei: datetimei_from_key(key)
        }
      end
    end

    def parse_json(raw)
      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end

    # performance|…|datetime|20200124T0523|datetimei|1579861423|…
    def datetime_from_key(key)
      parts = key.to_s.split("|")
      idx = parts.index("datetime")
      idx ? parts[idx + 1] : nil
    end

    def datetimei_from_key(key)
      parts = key.to_s.split("|")
      idx = parts.index("datetimei")
      idx ? parts[idx + 1].to_i : nil
    end

    def percentile(values, pct)
      return nil if values.empty?

      if defined?(RailsPerformance::Utils) && RailsPerformance::Utils.respond_to?(:percentile)
        return RailsPerformance::Utils.percentile(values, pct)
      end

      sorted = values.sort
      rank = (pct.to_f / 100) * (sorted.size - 1)
      lower = sorted[rank.floor]
      upper = sorted[rank.ceil]
      lower + (upper - lower) * (rank - rank.floor)
    end

    def average(values)
      return nil if values.empty?

      values.sum.to_f / values.size
    end

    # Bucket by minute (RP datetime key YYYYMMDDTHHMM) → rpm points sorted by bucket.
    def throughput_series(samples)
      buckets = Hash.new(0)
      samples.each do |sample|
        bucket = sample[:datetime]
        next if bucket.blank?

        buckets[bucket] += 1
      end
      buckets.keys.sort.map { |k| {datetime: k, rpm: buckets[k]} }
    end

    # Per-minute average duration for response-time chart (honest sample means, not invent).
    def response_time_series(samples)
      buckets = Hash.new { |h, k| h[k] = [] }
      samples.each do |sample|
        bucket = sample[:datetime]
        next if bucket.blank?
        next unless sample[:duration].is_a?(Numeric)

        buckets[bucket] << sample[:duration]
      end
      buckets.keys.sort.map do |k|
        vals = buckets[k]
        {datetime: k, avg: vals.sum.to_f / vals.size}
      end
    end

    def empty_result(budget_exceeded:)
      Result.new(
        p50: nil, p95: nil, p99: nil,
        throughput: [],
        response_series: [],
        sample_count: 0,
        avg_db_ms: nil,
        budget_exceeded: budget_exceeded
      )
    end

    def cache_key
      "performance/telemetry/v2"
    end
  end
end
