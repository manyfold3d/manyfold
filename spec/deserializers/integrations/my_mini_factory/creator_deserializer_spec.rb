require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::CreatorDeserializer do
  context "when creating from URI" do
    it "accepts user URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example")
      expect(deserializer).to be_valid
    end

    it "rejects non-user URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/objects/example")
      expect(deserializer).not_to be_valid
    end

    it "rejects user subfolder URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example/collection/what-ever")
      expect(deserializer).not_to be_valid
    end

    it "extracts username" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example")
      expect(deserializer.username).to eq "example"
    end
  end
end
