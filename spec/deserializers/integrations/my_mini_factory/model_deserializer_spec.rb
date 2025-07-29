require "rails_helper"

RSpec.describe Integrations::MyMiniFactory::ModelDeserializer, :mmf_api_key do
  context "when creating from URI" do
    it "accepts object URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/object/3d-print-example-1234")
      expect(deserializer).to be_valid
    end

    it "rejects non-object URIs" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/users/example")
      expect(deserializer).not_to be_valid
    end

    it "extracts object ID" do
      deserializer = described_class.new(uri: "https://www.myminifactory.com/object/3d-print-example-1234")
      expect(deserializer.model_id).to eq "1234"
    end
  end

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_MyMiniFactory_ModelDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/object/3d-print-michelangelo-s-david-in-florence-italy-2052" }

    it "extracts name" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:name]).to be true
      expect(deserializer.deserialize[:name]).to eq "David"
    end

    it "extracts slug" do
      expect(deserializer.deserialize[:slug]).to eq "michelangelo-s-david-in-florence-italy"
    end

    it "extracts description" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:notes]).to be true
      expect(deserializer.deserialize[:notes]).to include "Michelangelo"
    end

    it "extracts tags" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:tags]).to be true
      expect(deserializer.deserialize[:tag_list]).to include "renaissance-sculpture"
    end

    it "extracts image data to check and download" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:images]).to be true
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://dl.myminifactory.com/object-assets/579f9e3b648b5/images/david-2.jpg",
        filename: "david-2.jpg"
      })
    end

    it "extracts preview filename" do
      expect(deserializer.deserialize[:preview_filename]).to eq "david-2.jpg"
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

    it "does not import files" do
      expect(deserializer.capabilities[:model_files]).to be false
    end

    it "does not extract license" do
      expect(deserializer.capabilities[:license]).to be false
    end

    it "does not extract sensitive flag" do
      expect(deserializer.capabilities[:sensitive]).to be false
    end
  end

  context "with a valid URI" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/object/3d-print-michelangelo-s-david-in-florence-italy-2052" }

    it "deserializes to a Model" do
      expect(deserializer.capabilities[:class]).to eq Model
    end

    it "is valid for deserialization to Model" do
      expect(deserializer.valid?(for_class: Model)).to be true
    end

    it "is not valid for deserialization to Creator" do
      expect(deserializer.valid?(for_class: Creator)).to be false
    end

    it "is created for this URI by a link object" do # rubocop:disable RSpec/MultipleExpectations
      des = create(:link, url: uri, linkable: create(:model)).deserializer
      expect(des).to be_a(described_class)
      expect(des).to be_valid
    end
  end

  context "with URL that returns a 404", vcr: {cassette_name: "Integrations_MyMiniFactory_ModelDeserializer/not_found"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/object/3d-print-nope-9999999999999" }

    it "propagates client error" do
      expect { deserializer.deserialize }.to raise_error(Faraday::ResourceNotFound)
    end
  end
end
