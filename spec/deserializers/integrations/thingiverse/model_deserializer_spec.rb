require "rails_helper"

RSpec.describe Integrations::Thingiverse::ModelDeserializer, :thingiverse_api_key do
  context "when creating from URI" do
    it "accepts object URIs" do
      deserializer = described_class.new(uri: "https://www.thingiverse.com/thing:4049220")
      expect(deserializer).to be_valid
    end

    it "rejects non-object URIs" do
      deserializer = described_class.new(uri: "https://www.thingiverse.com/floppy_uk")
      expect(deserializer).not_to be_valid
    end

    it "extracts object ID" do
      deserializer = described_class.new(uri: "https://www.thingiverse.com/thing:4049220")
      expect(deserializer.object_id).to eq "4049220"
    end
  end

  context "when pulling data from MMF API", vcr: {cassette_name: "Integrations_Thingiverse_ModelDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.thingiverse.com/thing:4049220" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "Slatwall support"
    end

    it "extracts description" do
      expect(deserializer.deserialize[:notes]).to include "Slatwall plastic inserts"
    end

    it "extracts tags" do
      expect(deserializer.deserialize[:tag_list]).to include "slatwall"
    end

    it "extracts sensitive tag" do
      expect(deserializer.deserialize[:sensitive]).to be false
    end

    it "extracts image info to check and download" do
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://cdn.thingiverse.com/assets/81/fd/d4/4e/ec/Slatwall_support.png",
        filename: "images/Slatwall_support.png"
      })
    end

    it "extracts 3d file info to check and download" do
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://cdn.thingiverse.com/assets/62/09/06/48/fa/Slatwall_support.stl",
        filename: "files/Slatwall_support.stl"
      })
    end

    it "extracts preview filename" do
      expect(deserializer.deserialize[:preview_filename]).to eq "images/Slatwall_support.png"
    end

    it "matches existing creator" do
      creator = create(:creator, links_attributes: [{url: "https://www.thingiverse.com/floppy_uk"}])
      expect(deserializer.deserialize[:creator]).to eq creator
    end

    it "adds new creator if missing" do
      expect(deserializer.deserialize[:creator_attributes]).to include({
        name: "floppy_uk",
        links_attributes: [{url: "https://www.thingiverse.com/floppy_uk"}]
      })
    end
  end

  context "with a valid URI" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.thingiverse.com/thing:4049220" }

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
