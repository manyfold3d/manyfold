require "rails_helper"

RSpec.describe Integrations::Thingiverse::BaseDeserializer, :thingiverse_api_key do
  context "when creating from URI" do
    let(:canonical) { "https://www.thingiverse.com/floppy_uk" }

    it "validates URI" do
      deserializer = described_class.new(uri: canonical)
      expect(deserializer).to be_valid
    end

    it "canonicalizes http to https" do
      deserializer = described_class.new(uri: "http://www.thingiverse.com/floppy_uk")
      expect(deserializer.uri).to eq canonical
    end

    it "canonicalizes non-www to www" do
      deserializer = described_class.new(uri: "https://thingiverse.com/floppy_uk")
      expect(deserializer.uri).to eq canonical
    end

    it "removes query parts" do
      deserializer = described_class.new(uri: "https://www.thingiverse.com/floppy_uk?query=test")
      expect(deserializer.uri).to eq canonical
    end

    it "removes fragment parts" do
      deserializer = described_class.new(uri: "https://www.thingiverse.com/floppy_uk#section")
      expect(deserializer.uri).to eq canonical
    end

    it "rejects non-MMF domains" do
      deserializer = described_class.new(uri: "https://www.thïngiverse.com/floppy_uk")
      expect(deserializer).not_to be_valid
    end
  end
end
