require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::BaseDeserializer do
  let(:api_key) { ENV.fetch("MYMINIFACTORY_API_KEY", "abcd1234") }

  context "when creating from URI" do
    let(:canonical) { "https://www.myminifactory.com/users/example" }

    it "validates URI" do
      deserializer = described_class.new(uri: canonical, api_key: api_key)
      expect(deserializer).to be_valid
    end

    it "canonicalizes http to https" do
      deserializer = described_class.new(uri: "http://www.myminifactory.com/users/example", api_key: api_key)
      expect(deserializer.uri).to eq canonical
    end

    it "canonicalizes non-www to www" do
      deserializer = described_class.new(uri: "https://myminifactory.com/users/example", api_key: api_key)
      expect(deserializer.uri).to eq canonical
    end

    it "removes query parts" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example?show=store", api_key: api_key)
      expect(deserializer.uri).to eq canonical
    end

    it "removes fragment parts" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example#panel2-0", api_key: api_key)
      expect(deserializer.uri).to eq canonical
    end

    it "rejects non-MMF domains" do
      deserializer = described_class.new(uri: "https://www.mymïnïfactory.com/users/example", api_key: api_key)
      expect(deserializer).not_to be_valid
    end
  end
end
