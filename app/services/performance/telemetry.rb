# frozen_string_literal: true

# INIT-013/SPEC-002 — KPI / chart read path without Redis KEYS (ADR D-3 / D-4).
# Percentiles and throughput come from HTTP request samples only — never Sidekiq keys.
# INIT-013/SPEC-004 — response_series + avg_db_ms for dashboard charts / secondary stats.
# Follow-up — error_rate + apdex from HTTP status/duration (no invented N/A when samples exist).
module Performance
  class Telemetry
    REQUEST_MATCH = "performance|*"
    CACHE_TTL = 15.seconds
    APDEX_T_MS = 500.0

    Result = Data.define(
      :p50, :p95, :p99,
      :throughput,
      :response_series,
      :sample_count,
      :avg_db_ms,
      :error_rate,
      :apdex,
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
      return compute unless @cache

      cached = read_cache
      return cached if cached

      result = compute
      write_cache(result)
      result
    end

    private

    # Prefer Redis over Rails.cache — production defaults to FileStore under
    # tmp/cache, which is not reliably writable in the container (EACCES → 500).
    def read_cache
      client = redis_client
      return nil unless client

      raw = client.get(cache_key)
      return nil if raw.blank?

      data = JSON.parse(raw, symbolize_names: true)
      Result.new(**data)
    rescue StandardError
      nil
    end

    def write_cache(result)
      client = redis_client
      return unless client

      client.set(cache_key, result.to_h.to_json, ex: CACHE_TTL.to_i)
    rescue StandardError
      nil
    end

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
        error_rate: error_rate(samples),
        apdex: apdex_score(durations),
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
          status: status_from_key(key),
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

    # performance|…|status|200|datetime|20200124T0523|datetimei|1579861423|…
    def status_from_key(key)
      parts = key.to_s.split("|")
      idx = parts.index("status")
      return nil unless idx

      Integer(parts[idx + 1], exception: false)
    end

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

    def error_rate(samples)
      return nil if samples.empty?

      with_status = samples.select { |s| s[:status].is_a?(Integer) }
      return nil if with_status.empty?

      errors = with_status.count { |s| s[:status] >= 500 }
      (errors.to_f / with_status.size) * 100.0
    end

    # Apdex with T = APDEX_T_MS (satisfied ≤ T, tolerating ≤ 4T).
    def apdex_score(durations)
      return nil if durations.empty?

      satisfied = 0
      tolerating = 0
      durations.each do |ms|
        if ms <= APDEX_T_MS
          satisfied += 1
        elsif ms <= (APDEX_T_MS * 4)
          tolerating += 1
        end
      end
      (satisfied + (tolerating / 2.0)) / durations.size
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

    # Per-minute average duration + p95 for response-time chart.
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
        {
          datetime: k,
          avg: vals.sum.to_f / vals.size,
          p95: percentile(vals, 95)
        }
      end
    end

    def empty_result(budget_exceeded:)
      Result.new(
        p50: nil, p95: nil, p99: nil,
        throughput: [],
        response_series: [],
        sample_count: 0,
        avg_db_ms: nil,
        error_rate: nil,
        apdex: nil,
        budget_exceeded: budget_exceeded
      )
    end

    def cache_key
      "performance/telemetry/v4"
    end
  end
end
