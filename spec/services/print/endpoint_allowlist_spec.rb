# frozen_string_literal: true

require "rails_helper"

RSpec.describe Print::EndpointAllowlist do
  describe ".allowed?" do
    it "allows RFC1918 addresses" do
      expect(described_class.allowed?("10.0.0.199")).to be(true)
      expect(described_class.allowed?("192.168.1.1")).to be(true)
      expect(described_class.allowed?("172.16.0.5")).to be(true)
    end

    it "rejects public and link-local metadata addresses" do
      expect(described_class.allowed?("1.1.1.1")).to be(false)
      expect(described_class.allowed?("8.8.8.8")).to be(false)
      expect(described_class.allowed?("169.254.169.254")).to be(false)
    end
  end

  describe ".allowed_discover_target?" do
    it "allows limited broadcast and private LAN" do
      expect(described_class.allowed_discover_target?("255.255.255.255")).to be(true)
      expect(described_class.allowed_discover_target?("10.0.0.255")).to be(true)
    end

    it "rejects public discover targets" do
      expect(described_class.allowed_discover_target?("1.1.1.1")).to be(false)
    end
  end

  describe ".filter_discover_targets" do
    it "drops public hosts and keeps private + broadcast" do
      expect(described_class.filter_discover_targets(%w[1.1.1.1 10.0.0.255 255.255.255.255])).to eq(
        %w[10.0.0.255 255.255.255.255]
      )
    end
  end
end
