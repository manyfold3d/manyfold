require "rails_helper"

RSpec.describe Integrations::Cults3d::BaseDeserializer, :cults3d_api_key do
  context "when creating from URI" do
    let(:canonical) { "https://cults3d.com/en/users/CreativeTools" }

    it "validates URI" do
      deserializer = described_class.new(uri: canonical)
      expect(deserializer).to be_valid
    end

    it "canonicalizes http to https" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools")
      expect(deserializer.uri).to eq canonical
    end

    it "removes query parts" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools?query=test")
      expect(deserializer.uri).to eq canonical
    end

    it "removes fragment parts" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools#section")
      expect(deserializer.uri).to eq canonical
    end

    it "rejects non-MMF domains" do
      deserializer = described_class.new(uri: "https://cülts3d.com/en/users/CreativeTools")
      expect(deserializer).not_to be_valid
    end
  end
end
