require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::CreatorDeserializer, :mmf_api_key do
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

    it "extracts username including underscore" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example_user")
      expect(deserializer.username).to eq "example_user"
    end
  end

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_MyMiniFactory_CreatorDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World" }

    it "extracts name" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:name]).to be true
      expect(deserializer.deserialize[:name]).to eq "Scan The World"
    end

    it "extracts slug" do
      expect(deserializer.deserialize[:slug]).to eq "scan-the-world"
    end

    it "extracts bio" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:notes]).to be true
      expect(deserializer.deserialize[:notes]).to include "cultural artefacts"
    end
  end

  context "with a valid configuration" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World" }

    it "deserializes to a Creator" do
      expect(deserializer.capabilities[:class]).to eq Creator
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

  context "with URL that returns a 404", vcr: {cassette_name: "Integrations_MyMiniFactory_CreatorDeserializer/not_found"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/users/ThisUserDoesNotExist" }

    it "propagates client error" do
      expect { deserializer.deserialize }.to raise_error(Faraday::ResourceNotFound)
    end
  end
end
