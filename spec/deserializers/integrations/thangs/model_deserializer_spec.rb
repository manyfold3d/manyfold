require "rails_helper"

RSpec.describe Integrations::Thangs::ModelDeserializer, :thingiverse_api_key do
  context "when creating from URI" do
    it "accepts object URIs" do
      deserializer = described_class.new(uri: "https://thangs.com/designer/CHEP/3d-model/CHEP%20Cube%20-%20Calibration%20Cube-29638")
      expect(deserializer).to be_valid
    end

    it "rejects non-object URIs" do
      deserializer = described_class.new(uri: "https://thangs.com/designer/CHEP")
      expect(deserializer).not_to be_valid
    end

    it "extracts object ID" do
      deserializer = described_class.new(uri: "https://thangs.com/designer/CHEP/3d-model/CHEP%20Cube%20-%20Calibration%20Cube-29638")
      expect(deserializer.object_id).to eq "29638"
    end
  end

  context "when pulling data from API", vcr: {cassette_name: "Integrations_Thangs_ModelDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://thangs.com/designer/CHEP/3d-model/CHEP%20Cube%20-%20Calibration%20Cube-29638" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "CHEP Cube - Calibration Cube"
    end

    it "extracts description" do
      expect(deserializer.deserialize[:notes]).to include "designed my own"
    end

    it "extracts image info to check and download" do
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://storage.googleapis.com/production-thangs-public/uploads/attachments/cd36783e-7120-4b32-850f-00bd9059eff6/Chep%20Cube%20Print.jpg",
        filename: "Chep Cube Print.jpg"
      })
    end

    it "matches existing creator" do
      creator = create(:creator, links_attributes: [{url: "https://thangs.com/designer/CHEP"}])
      expect(deserializer.deserialize[:creator]).to eq creator
    end

    it "adds new creator if missing" do
      expect(deserializer.deserialize[:creator_attributes]).to include({
        name: "CHEP",
        links_attributes: [{url: "https://thangs.com/designer/CHEP"}]
      })
    end
  end

  context "with a valid URI" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://thangs.com/designer/CHEP/3d-model/CHEP%20Cube%20-%20Calibration%20Cube-29638" }

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
