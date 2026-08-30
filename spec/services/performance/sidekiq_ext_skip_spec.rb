# frozen_string_literal: true

require "rails_helper"

# INIT-013/SPEC-002
RSpec.describe Performance::SidekiqExtSkip do
  before do
    RailsPerformanceSidekiqStub.ensure_loaded!
    described_class.install!
  end

  it "is prepended onto RailsPerformance::Gems::SidekiqExt" do
    expect(RailsPerformance::Gems::SidekiqExt.ancestors).to include(described_class)
  end

  it "skips record.save for BroadcastStreamJob (write-path)" do # rubocop:disable RSpec/ExampleLength
    ext = RailsPerformance::Gems::SidekiqExt.new
    worker = Object.new
    msg = broadcast_msg
    allow(RailsPerformance::Models::SidekiqRecord).to receive(:new)
    result = ext.call(worker, msg, "default") { :ok }
    expect(result).to eq(:ok)
    expect(RailsPerformance::Models::SidekiqRecord).not_to have_received(:new)
  end

  it "still records non-skipped workers" do # rubocop:disable RSpec/ExampleLength
    ext = RailsPerformance::Gems::SidekiqExt.new
    worker = Object.new
    msg = scan_msg
    saved = false
    allow(RailsPerformance::Models::SidekiqRecord).to receive(:new).and_wrap_original do |orig, **kwargs|
      record = orig.call(**kwargs)
      allow(record).to receive(:save) { saved = true }
      record
    end
    result = ext.call(worker, msg, "default") { :worked }
    expect(result).to eq(:worked)
    expect(saved).to be(true)
  end

  def broadcast_msg
    {
      "wrapped" => "Turbo::Streams::BroadcastStreamJob",
      "jid" => "abc",
      "enqueued_at" => Time.now.to_f,
      "created_at" => Time.now.to_f
    }
  end

  def scan_msg
    {
      "wrapped" => "Scan::CheckAllJob",
      "jid" => "def",
      "enqueued_at" => Time.now.to_f,
      "created_at" => Time.now.to_f
    }
  end
end
