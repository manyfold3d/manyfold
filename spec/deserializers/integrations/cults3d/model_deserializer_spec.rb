require "rails_helper"

RSpec.describe Integrations::Cults3d::ModelDeserializer, :cults3d_api_key do
  context "when creating from URI" do
    it "accepts object URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/3d-model/tool/3dbenchy-the-jolly-3d-printing-torture-test")
      expect(deserializer).to be_valid
    end

    it "accepts localised object URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/de/modell-3d/werkzeuge/3dbenchy-the-jolly-3d-printing-torture-test")
      expect(deserializer).to be_valid
    end

    it "rejects non-object URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/collections/best-stl-files-3d-printer-starting-kit")
      expect(deserializer).not_to be_valid
    end

    it "extracts object slug" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/3d-model/tool/3dbenchy-the-jolly-3d-printing-torture-test")
      expect(deserializer.object_slug).to eq "3dbenchy-the-jolly-3d-printing-torture-test"
    end
  end

  context "when pulling data from API", vcr: {cassette_name: "Integrations_Cults3d_ModelDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/3d-model/tool/3dbenchy-the-jolly-3d-printing-torture-test" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "Benchy - The jolly 3D printing torture-test"
    end

    it "extracts description" do
      expect(deserializer.deserialize[:notes]).to include "3DBenchy"
    end

    it "extracts tags" do
      expect(deserializer.deserialize[:tag_list]).to include "calibrate"
    end

    it "extracts sensitive tag" do
      expect(deserializer.deserialize[:sensitive]).to be false
    end

    it "extracts image info to check and download" do
      expect(deserializer.deserialize[:file_urls]).to include({
        url: "https://fbi.cults3d.com/uploaders/133/illustration-file/1428782346-8151-9279/_1__3D-printed__3DBenchy_by_Creative-Tools.com.JPG",
        filename: "_1__3D-printed__3DBenchy_by_Creative-Tools.com.JPG"
      })
    end

    it "extracts preview filename" do
      expect(deserializer.deserialize[:preview_filename]).to eq "_1__3D-printed__3DBenchy_by_Creative-Tools.com.JPG"
    end

    it "extracts license" do
      expect(deserializer.deserialize[:license]).to eq "CC-BY-ND-4.0"
    end

    it "matches existing creator" do
      creator = create(:creator, links_attributes: [{url: "https://cults3d.com/en/users/CreativeTools"}])
      expect(deserializer.deserialize[:creator]).to eq creator
    end

    it "adds new creator if missing" do
      expect(deserializer.deserialize[:creator_attributes]).to include({
        name: "CreativeTools",
        links_attributes: [{url: "https://cults3d.com/en/users/CreativeTools"}]
      })
    end
  end

  context "with a valid URI" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/3d-model/tool/3dbenchy-the-jolly-3d-printing-torture-test" }

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
