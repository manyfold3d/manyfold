require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::CollectionDeserializer, :mmf_api_key do
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

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_MyMiniFactory_CollectionDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World/collection/sutton-hoo-artifacts" }

    it "extracts name" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:name]).to be true
      expect(deserializer.deserialize[:name]).to eq "Sutton Hoo Artifacts"
    end

    it "does not extract notes" do
      expect(deserializer.capabilities[:notes]).to be false
    end

    it "matches existing creator" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:creator]).to be true
      creator = create(:creator, links_attributes: [{url: "https://www.myminifactory.com/users/Scan%20The%20World"}])
      expect(deserializer.deserialize[:creator]).to eq creator
    end

    it "adds new creator if missing" do
      expect(deserializer.deserialize[:creator_attributes]).to include({
        name: "Scan The World",
        links_attributes: [{url: "https://www.myminifactory.com/users/Scan%20The%20World"}]
      })
    end

    it "gets a list of models" do
      expect(deserializer.deserialize[:models]).to include("https://www.myminifactory.com/object/3d-print-sutton-hoo-helmet-26138")
    end
  end

  context "with a valid configuration" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/users/Scan%20The%20World/collection/sutton-hoo-artifacts" }

    it "deserializes to a Collection" do
      expect(deserializer.capabilities[:class]).to eq Collection
    end

    it "is valid for deserialization to Collection" do
      expect(deserializer.valid?(for_class: Collection)).to be true
    end

    it "is not valid for deserialization to Model" do
      expect(deserializer.valid?(for_class: Model)).to be false
    end

    it "is created for this URI by a link object" do # rubocop:disable RSpec/MultipleExpectations
      des = create(:link, url: uri, linkable: create(:collection)).deserializer
      expect(des).to be_a(described_class)
      expect(des).to be_valid
    end
  end
end
