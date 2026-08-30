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
    expect(result.response_series).to eq([
      {datetime: "20260830T0800", avg: 15.0},
      {datetime: "20260830T0801", avg: 30.0}
    ])
    expect(result.avg_db_ms).to eq(2.0)
    expect(result.budget_exceeded).to be(false)
    expect(redis).not_to have_received(:keys)
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

  it "sets budget_exceeded when SCAN iteration budget is hit" do
    result = described_class.new(redis: redis, cache: false, max_iterations: 0).call
    expect(result.budget_exceeded).to be(true)
  end

  it "never invokes Redis KEYS (Utils.fetch_from_redis path forbidden)" do
    allow(redis).to receive(:keys).and_call_original
    described_class.new(redis: redis, cache: false).call
    expect(redis).not_to have_received(:keys)
  end
end
