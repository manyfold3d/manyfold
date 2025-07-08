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

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_MyMiniFactory_CreatorDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri, api_key: api_key) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "Scan The World"
    end

    it "extracts bio" do
      expect(deserializer.deserialize[:notes]).to include "cultural artefacts"
    end
  end

  context "with a valid configuration" do
    subject(:deserializer) { described_class.new(uri: uri, api_key: api_key) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World" }

    it "deserializes to a Creator" do
      expect(deserializer.send(:target_class)).to eq Creator
    end

    it "is valid for deserialization to Creator" do
      expect(deserializer.valid?(for_class: Creator)).to be true
    end

    it "is not valid for deserialization to Model" do
      expect(deserializer.valid?(for_class: Model)).to be false
    end

    it "is created for this URI by a link object" do # rubocop:disable RSpec/MultipleExpectations
      des = create(:link, url: uri, linkable: create(:creator)).deserializer
      expect(des).to be_a(described_class)
      expect(des).to be_valid
    end
  end
end
