# frozen_string_literal: true

require "rails_helper"

# INIT-013/SPEC-002
RSpec.describe Performance::SkippedWorkers do
  it "includes Turbo::Streams::BroadcastStreamJob by default" do
    expect(described_class::NAMES).to include("Turbo::Streams::BroadcastStreamJob")
    expect(described_class.include?("Turbo::Streams::BroadcastStreamJob")).to be(true)
  end

  it "does not skip application scan jobs" do
    expect(described_class.include?("Scan::CheckAllJob")).to be(false)
  end
end
