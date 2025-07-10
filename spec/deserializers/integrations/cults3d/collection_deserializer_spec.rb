require "rails_helper"

RSpec.describe Integrations::Cults3d::CollectionDeserializer, :cults3d_api_key do
  context "when creating from URI" do
    it "accepts collection URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/collections/best-stl-files-3d-printer-starting-kit")
      expect(deserializer).to be_valid
    end

    it "accepts localized collection URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/ru/kollektsii/best-stl-files-3d-printer-starting-kit")
      expect(deserializer).to be_valid
    end

    it "rejects non-collection URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools")
      expect(deserializer).not_to be_valid
    end

    it "extracts collection slug" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/collections/best-stl-files-3d-printer-starting-kit")
      expect(deserializer.collection_slug).to eq "best-stl-files-3d-printer-starting-kit"
    end
  end

  context "when pulling data from API", vcr: {cassette_name: "Integrations_Cults3d_CollectionDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/collections/best-stl-files-3d-printer-starting-kit" }

    it "extracts name" do
      expect(deserializer.deserialize[:name]).to eq "▶️ 3D Printing the best Starter Kit"
    end

    it "extracts description" do
      expect(deserializer.deserialize[:notes]).to include "calibration"
    end
  end

  context "with a valid configuration" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/collections/best-stl-files-3d-printer-starting-kit" }

    it "deserializes to a Collection" do
      expect(deserializer.send(:target_class)).to eq Collection
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
