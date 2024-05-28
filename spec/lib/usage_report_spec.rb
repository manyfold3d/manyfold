require "rails_helper"

RSpec.describe UsageReport do
  context "when generating a usage report" do
    before do
      allow(SiteSettings).to receive(:anonymous_usage_id).and_return("guid-goes-here")
      allow(Rails.application.config).to receive_messages(
        app_version: "test",
        git_sha: "deadbeef"
      )
    end

    let(:report) { described_class.generate }
    let(:parsed) { JSON.parse(report) }

    it "produces valid JSON" do
      expect(parsed).not_to be_nil
    end

    it "includes application ID" do
      expect(parsed["id"]).to eq "guid-goes-here"
    end

    it "includes application version" do
      expect(parsed["version"]["app"]).to eq "test"
    end

    it "includes git SHA" do
      expect(parsed["version"]["sha"]).to eq "deadbeef"
    end
  end

  it "specifies a default endpoint" do
    ClimateControl.modify USAGE_TRACKING_URL: nil do
      expect(described_class.endpoint).to eq "https://tracking.manyfold.app"
    end
  end

  it "allows custom endpoint in ENV" do
    ClimateControl.modify USAGE_TRACKING_URL: "http://example.com" do
      expect(described_class.endpoint).to eq "http://example.com"
    end
  end
end
