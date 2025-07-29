require "rails_helper"

RSpec.describe Integrations::Cults3d::CreatorDeserializer, :cults3d_api_key do
  context "when creating from URI" do
    it "accepts user URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools")
      expect(deserializer).to be_valid
    end

    it "rejects non-user URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/3d-model/tool/3dbenchy-the-jolly-3d-printing-torture-test")
      expect(deserializer).not_to be_valid
    end

    it "rejects user subfolder URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools/followers")
      expect(deserializer).not_to be_valid
    end

    it "accepts user model list URI" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools/3d-models")
      expect(deserializer).to be_valid
    end

    it "handles translated URIs" do
      deserializer = described_class.new(uri: "https://cults3d.com/pt/usuarios/CreativeTools")
      expect(deserializer).to be_valid
    end

    it "handles translated model list URI" do
      deserializer = described_class.new(uri: "https://cults3d.com/pt/usuarios/CreativeTools/modelos-3d")
      expect(deserializer).to be_valid
    end

    it "extracts username" do
      deserializer = described_class.new(uri: "https://cults3d.com/en/users/CreativeTools")
      expect(deserializer.username).to eq "CreativeTools"
    end
  end

  context "when pulling data from API", vcr: {cassette_name: "Integrations_Cults3d_CreatorDeserializer/success"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/users/CreativeTools" }

    it "extracts name" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:name]).to be true
      expect(deserializer.deserialize[:name]).to eq "CreativeTools"
    end

    it "extracts slug" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.deserialize[:slug]).to eq "creativetools"
    end

    it "extracts bio" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserializer.capabilities[:notes]).to be true
      expect(deserializer.deserialize[:notes]).to include "all things 3D"
    end
  end

  context "with a valid configuration" do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/users/CreativeTools" }

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

  context "with URL that returns a 404", vcr: {cassette_name: "Integrations_Cults3d_CreatorDeserializer/not_found"} do
    subject(:deserializer) { described_class.new(uri: uri) }

    let(:uri) { "https://cults3d.com/en/users/ThisUserDoesNotExist" }

    it "propagates client error" do
      expect { deserializer.deserialize }.to raise_error(Faraday::ResourceNotFound)
    end
  end
end
