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
      expect(deserializer.object_id).to eq "1234"
    end
  end

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_MyMiniFactory_ModelDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/object/3d-print-michelangelo-s-david-in-florence-italy-2052" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "David"
    end

    it "extracts description" do
      expect(deserializer.deserialize[:notes]).to include "Michelangelo"
    end

    it "extracts tags" do
      expect(deserializer.deserialize[:tag_list]).to include "renaissance-sculpture"
    end

    it "extracts image data to check and download" do
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://dl.myminifactory.com/object-assets/579f9e3b648b5/images/david-2.jpg",
        filename: "david-2.jpg"
      })
    end

    it "extracts 3d file info to check and download" do
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://www.myminifactory.com/download/2052?downloadfile=scan-the-world-michelangelo-s-david.stl",
        filename: "scan-the-world-michelangelo-s-david.stl"
      })
    end

    it "extracts preview filename" do
      expect(deserializer.deserialize[:preview_filename]).to eq "david-2.jpg"
    end

    it "extracts creator"
  end

  context "with a valid URI" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.myminifactory.com/object/3d-print-michelangelo-s-david-in-florence-italy-2052" }

    it "deserializes to a Model" do
      expect(deserializer.send(:target_class)).to eq Model
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
end
