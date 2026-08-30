# frozen_string_literal: true

require "rails_helper"

# INIT-013/SPEC-002
RSpec.describe Performance::Telemetry do
  let(:redis) { PerformanceRedisFake.new }

  def request_key(datetime:, datetimei:, duration:, request_id: "rid-1")
    "performance|controller|HomeController|action|index|format|html|status|200|" \
      "datetime|#{datetime}|datetimei|#{datetimei}|method|GET|path|/|request_id|#{request_id}|END|1.0.0"
  end

  before do
    redis.set(
      request_key(datetime: "20260830T0800", datetimei: 1_725_000_000, duration: 10, request_id: "a"),
      {duration: 10, view_runtime: 1, db_runtime: 2}.to_json
    )
    redis.set(
      request_key(datetime: "20260830T0800", datetimei: 1_725_000_001, duration: 20, request_id: "b"),
      {duration: 20, view_runtime: 1, db_runtime: 2}.to_json
    )
    redis.set(
      request_key(datetime: "20260830T0801", datetimei: 1_725_000_060, duration: 30, request_id: "c"),
      {duration: 30, view_runtime: 1, db_runtime: 2}.to_json
    )
    redis.set(
      "sidekiq|queue|default|worker|Turbo::Streams::BroadcastStreamJob|jid|x|" \
        "datetime|20260830T0800|datetimei|1|enqueued_ati|1|start_timei|1|status|success|END|1.0.0",
      {duration: 9999, message: nil}.to_json
    )
  end

  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
  it "returns p50/p95/p99 and throughput without calling KEYS" do
    allow(redis).to receive(:keys).and_call_original
    result = described_class.new(redis: redis, cache: false).call

    expect(result.sample_count).to eq(3)
    expect(result.p50).to eq(20.0)
    expect(result.p95).to be_within(0.01).of(29.0)
    expect(result.p99).to be_within(0.01).of(29.8)
    expect(result.throughput).to eq([
      {datetime: "20260830T0800", rpm: 2},
      {datetime: "20260830T0801", rpm: 1}
    ])
    expect(result.response_series.size).to eq(2)
    expect(result.response_series[0][:datetime]).to eq("20260830T0800")
    expect(result.response_series[0][:avg]).to eq(15.0)
    expect(result.response_series[0][:p95]).to be_within(0.01).of(19.5)
    expect(result.response_series[1]).to eq(datetime: "20260830T0801", avg: 30.0, p95: 30.0)
    expect(result.avg_db_ms).to eq(2.0)
    expect(result.error_rate).to eq(0.0)
    expect(result.apdex).to eq(1.0)
    expect(result.budget_exceeded).to be(false)
    expect(redis).not_to have_received(:keys)
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

  it "computes error rate and Apdex from status and duration" do
    redis.set(
      "performance|controller|X|action|y|format|html|status|500|" \
        "datetime|20260830T0802|datetimei|1725000120|method|GET|path|/boom|request_id|e|END|1.0.0",
      {duration: 50, view_runtime: 1, db_runtime: 1}.to_json
    )
    result = described_class.new(redis: redis, cache: false).call
    expect(result.sample_count).to eq(4)
    expect(result.error_rate).to eq(25.0)
    expect(result.apdex).to eq(1.0)
  end

  it "sets budget_exceeded when SCAN iteration budget is hit" do
    result = described_class.new(redis: redis, cache: false, max_iterations: 0).call
    expect(result.budget_exceeded).to be(true)
  end

  it "caches Result in Redis (not Rails.cache file store)" do
    allow(Rails).to receive(:cache).and_raise("Rails.cache must not be used")
    first = described_class.new(redis: redis, cache: true).call
    # Mutate underlying samples; cached result must still win within TTL
    redis.set(
      request_key(datetime: "20260830T0803", datetimei: 1_725_000_180, duration: 999, request_id: "d"),
      {duration: 999, view_runtime: 1, db_runtime: 1}.to_json
    )
    second = described_class.new(redis: redis, cache: true).call
    expect(second.sample_count).to eq(first.sample_count)
    expect(second.sample_count).to eq(3)
  end

  it "never invokes Redis KEYS (Utils.fetch_from_redis path forbidden)" do
    allow(redis).to receive(:keys).and_call_original
    described_class.new(redis: redis, cache: false).call
    expect(redis).not_to have_received(:keys)
  end
end
