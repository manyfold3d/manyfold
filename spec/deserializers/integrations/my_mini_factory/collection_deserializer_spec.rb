require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::CollectionDeserializer do
  context "when creating from URI" do
    it "accepts collection URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example/collection/what-ever")
      expect(deserializer).to be_valid
    end

    it "rejects non-collection URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example")
      expect(deserializer).not_to be_valid
    end

    it "extracts collection slug" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example/collection/what-ever")
      expect(deserializer.collection_slug).to eq "what-ever"
    end
  end
end
