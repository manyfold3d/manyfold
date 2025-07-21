require "rails_helper"

RSpec.describe Integrations::Thangs::BaseDeserializer, :thingiverse_api_key do
  context "when creating from URI" do
    let(:canonical) { "https://thangs.com/designer/CHEP" }

    it "validates URI" do
      pending "Disabled until we have clarity on API usage"
      deserializer = described_class.new(uri: canonical)
      expect(deserializer).to be_valid
    end

    it "canonicalizes http to https" do
      deserializer = described_class.new(uri: "http://thangs.com/designer/CHEP")
      expect(deserializer.uri).to eq canonical
    end

    it "removes query parts" do
      deserializer = described_class.new(uri: "https://thangs.com/designer/CHEP?query=test")
      expect(deserializer.uri).to eq canonical
    end

    it "removes fragment parts" do
      deserializer = described_class.new(uri: "https://thangs.com/designer/CHEP#section")
      expect(deserializer.uri).to eq canonical
    end

    it "rejects non-MMF domains" do
      deserializer = described_class.new(uri: "https://thängs.com/designer/CHEP")
      expect(deserializer).not_to be_valid
    end
  end
end
