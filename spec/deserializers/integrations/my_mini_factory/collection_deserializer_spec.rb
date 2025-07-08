require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::CollectionDeserializer do
  let(:api_key) { ENV.fetch("MYMINIFACTORY_API_KEY", "abcd1234") }

  context "when creating from URI" do
    it "accepts collection URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example/collection/what-ever", api_key: api_key)
      expect(deserializer).to be_valid
    end

    it "rejects non-collection URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example", api_key: api_key)
      expect(deserializer).not_to be_valid
    end

    it "extracts collection slug" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example/collection/what-ever", api_key: api_key)
      expect(deserializer.collection_slug).to eq "what-ever"
    end
  end

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_MyMiniFactory_CollectionDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri, api_key: api_key) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World/collection/sutton-hoo-artifacts" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "Sutton Hoo Artifacts"
    end
  end
end
