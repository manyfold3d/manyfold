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
      expect(deserializer.model_id).to eq "4049220"
    end
  end

  context "when pulling data from API", vcr: {cassette_name: "Integrations_Thingiverse_ModelDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.thingiverse.com/thing:4049220" }

    it "extracts name" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:name]).to be true
      expect(deserializer.deserialize[:name]).to eq "Slatwall support"
    end

    it "extracts slug" do
      expect(deserializer.deserialize[:slug]).to eq "slatwall-support"
    end

    it "extracts description" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:notes]).to be true
      expect(deserializer.deserialize[:notes]).to include "Slatwall plastic inserts"
    end

    it "extracts tags" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:tags]).to be true
      expect(deserializer.deserialize[:tag_list]).to include "slatwall"
    end

    it "extracts sensitive tag" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:sensitive]).to be true
      expect(deserializer.deserialize[:sensitive]).to be false
    end

    it "extracts image info to check and download" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:images]).to be true
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://cdn.thingiverse.com/assets/81/fd/d4/4e/ec/Slatwall_support.png",
        filename: "images/Slatwall_support.png"
      })
    end

    it "extracts 3d file info to check and download" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:model_files]).to be true
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://cdn.thingiverse.com/assets/62/09/06/48/fa/Slatwall_support.stl",
        filename: "files/Slatwall_support.stl"
      })
    end

    it "extracts preview filename" do
      expect(deserializer.deserialize[:preview_filename]).to eq "images/Slatwall_support.png"
    end

    it "matches existing creator" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:creator]).to be true
      creator = create(:creator, links_attributes: [{url: "https://www.thingiverse.com/floppy_uk"}])
      expect(deserializer.deserialize[:creator]).to eq creator
    end

    it "adds new creator if missing" do
      expect(deserializer.deserialize[:creator_attributes]).to include({
        name: "floppy_uk",
        links_attributes: [{url: "https://www.thingiverse.com/floppy_uk"}]
      })
    end

    it "does not extract license" do
      expect(deserializer.capabilities[:license]).to be false
    end
  end

  context "when pulling data from API with alternate file organisation", vcr: {cassette_name: "Integrations_Thingiverse_ModelDeserializer/alt_success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.thingiverse.com/thing:5993539" }

    it "extracts image file info" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://cdn.thingiverse.com/assets/d7/ce/a5/fb/aa/4a45092e-4832-4b2b-91f9-e99793b0f2f4.png",
        filename: "images/4a45092e-4832-4b2b-91f9-e99793b0f2f4.png"
      })
    end

    it "extracts preview filename" do
      expect(deserializer.deserialize[:preview_filename]).to eq "images/4a45092e-4832-4b2b-91f9-e99793b0f2f4.png"
    end

    it "extracts 3d file info to check and download" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://cdn.thingiverse.com/assets/29/08/99/88/05/4a45092e-4832-4b2b-91f9-e99793b0f2f4.stl",
        filename: "files/My_Modded_BLtouch_Mount.stl"
      })
    end
  end

  context "with a valid URI" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://www.thingiverse.com/thing:4049220" }

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
end
