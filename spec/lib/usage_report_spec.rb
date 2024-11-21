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

    it "includes architecture" do
      stub_const("RUBY_PLATFORM", "test-arch")
      expect(parsed["arch"]).to eq "test-arch"
    end

    it "includes application version" do
      expect(parsed["version"]["app"]).to eq "test"
    end

    it "includes image type" do
      ClimateControl.modify DOCKER_TAG: "ghcr.io/manyfold3d/manyfold:latest" do
        expect(JSON.parse(described_class.generate)["version"]["image"]).to eq "ghcr.io/manyfold3d/manyfold"
      end
    end

    it "works if there is no image type" do
      ClimateControl.modify DOCKER_TAG: nil do
        expect(JSON.parse(described_class.generate)["version"]["image"]).to be_nil
      end
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
