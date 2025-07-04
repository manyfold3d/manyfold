require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::CreatorDeserializer do
  let(:api_key) { ENV.fetch("MYMINIFACTORY_API_KEY", "abcd1234") }

  context "when creating from URI" do
    it "accepts user URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example", api_key: api_key)
      expect(deserializer).to be_valid
    end

    it "rejects non-user URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/objects/example", api_key: api_key)
      expect(deserializer).not_to be_valid
    end

    it "rejects user subfolder URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example/collection/what-ever", api_key: api_key)
      expect(deserializer).not_to be_valid
    end

    it "extracts username" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example", api_key: api_key)
      expect(deserializer.username).to eq "example"
    end
  end
end
