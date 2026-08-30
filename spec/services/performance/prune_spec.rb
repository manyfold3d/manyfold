# frozen_string_literal: true

require "rails_helper"

# INIT-013/SPEC-002
RSpec.describe Performance::Prune do
  let(:redis) { PerformanceRedisFake.new }

  let!(:orphan_key) do
    key = "performance|controller|X|action|y|format|html|status|200|datetime|20260830T0100|" \
      "datetimei|1|method|GET|path|/|request_id|orphan|END|1.0.0"
    redis.set(key, {duration: 1}.to_json) # no TTL → orphan
    key
  end

  let!(:fresh_key) do
    key = "performance|controller|X|action|y|format|html|status|200|datetime|20260830T0200|" \
      "datetimei|2|method|GET|path|/|request_id|fresh|END|1.0.0"
    redis.set(key, {duration: 2}.to_json, ex: 3600)
    key
  end

  let!(:broadcast_key) do
    key = "sidekiq|queue|default|worker|Turbo::Streams::BroadcastStreamJob|jid|z|" \
      "datetime|20260830T0300|datetimei|3|enqueued_ati|3|start_timei|3|status|success|END|1.0.0"
    redis.set(key, {duration: 5}.to_json, ex: 3600) # still deletable via deny list
    key
  end

  it "dry-run returns would_delete / keep counts without deleting" do
    result = described_class.new(redis: redis, dry_run: true).call

    expect(result.dry_run).to be(true)
    expect(result.would_delete).to eq(2) # orphan + broadcast
    expect(result.keep).to eq(1)
    expect(result.deleted).to eq(0)
    expect(redis.key_list).to include(orphan_key, fresh_key, broadcast_key)
    expect { redis.keys("*") }.to raise_error(PerformanceRedisFake::KeysForbidden)
  end

  it "mutate deletes orphans and deny-listed worker keys" do
    result = described_class.new(redis: redis, dry_run: false).call

    expect(result.dry_run).to be(false)
    expect(result.deleted).to eq(2)
    expect(redis.key_list).to eq([fresh_key])
    expect(redis.key_list).not_to include(orphan_key, broadcast_key)
  end

  it "uses SCAN only (tracks scan calls)" do
    described_class.new(redis: redis, dry_run: true).call
    expect(redis.scan_calls).to be > 0
  end
end
