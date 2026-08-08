require "rails_helper"

RSpec.describe Integrations::MakerWorld::ModelDeserializer do
  include WebMock::API

  let(:uri) { "https://makerworld.com/en/models/1400373-example-model#profileId-1452154" }
  let(:design_url) { "https://api.bambulab.com/v1/design-service/design/1400373" }
  let(:download_url) { "https://api.bambulab.com/v1/iot-service/api/user/profile/298919107?model_id=US2bb73b106683e5" }
  let(:signed_url) { "https://makerworld.bblmw.com/makerworld/model/example.3mf?at=1&exp=2&key=signed" }
  let(:design_body) do
    {
      title: "Stackable Painting Cone",
      summary: "A small shop helper.",
      modelId: "US2bb73b106683e5",
      coverUrl: "https://makerworld.bblmw.com/makerworld/model/cover.png",
      tags: [{name: "shop"}, {tagName: "painting"}],
      categories: [{name: "Tools"}],
      license: {spdxId: "CC-BY-4.0"},
      designer: {
        name: "Created Workshop",
        handle: "createdworkshop"
      },
      instances: [
        {id: 1452154, profileId: 298919107}
      ]
    }.to_json
  end

  before do
    stub_request(:get, design_url).to_return(status: 200, body: design_body, headers: {"Content-Type" => "application/json"})
  end

  context "when creating from URI" do
    it "accepts model URIs and canonicalizes them" do # rubocop:disable RSpec/MultipleExpectations
      deserializer = described_class.new(uri: uri)
      expect(deserializer).to be_valid
      expect(deserializer.uri).to eq "https://makerworld.com/models/1400373#profileId-1452154"
    end

    it "accepts scheme-less MakerWorld URIs" do # rubocop:disable RSpec/MultipleExpectations
      deserializer = described_class.new(uri: "makerworld.com/models/1400373")
      expect(deserializer).to be_valid
      expect(deserializer.uri).to eq "https://makerworld.com/models/1400373"
    end

    it "rejects non-model URIs" do
      deserializer = described_class.new(uri: "https://makerworld.com/en/@createdworkshop")
      expect(deserializer).not_to be_valid
    end

    it "extracts model and profile IDs" do # rubocop:disable RSpec/MultipleExpectations
      deserializer = described_class.new(uri: uri)
      expect(deserializer.model_id).to eq "1400373"
      expect(deserializer.profile_id).to eq "1452154"
    end
  end

  context "when pulling data from API" do
    subject(:deserialized) { described_class.new(uri: uri).deserialize }

    it "extracts metadata" do # rubocop:disable RSpec/ExampleLength
      expect(deserialized).to include(
        name: "Stackable Painting Cone",
        slug: "stackable-painting-cone",
        notes: "A small shop helper.",
        tag_list: contain_exactly("shop", "painting", "Tools"),
        license: "CC-BY-4.0"
      )
    end

    it "handles string license values" do # rubocop:disable RSpec/ExampleLength
      stub_request(:get, design_url).to_return(
        status: 200,
        body: JSON.parse(design_body).merge("license" => "CC-BY-NC-SA-4.0").to_json,
        headers: {"Content-Type" => "application/json"}
      )

      expect(deserialized[:license]).to eq "CC-BY-NC-SA-4.0"
    end

    it "extracts image info" do # rubocop:disable RSpec/MultipleExpectations
      expect(deserialized[:file_urls]).to include({
        url: "https://makerworld.bblmw.com/makerworld/model/cover.png",
        filename: "images/cover.png"
      })
      expect(deserialized[:preview_filename]).to eq "images/cover.png"
    end

    it "adds new creator if missing" do
      expect(deserialized[:creator_attributes]).to include({
        name: "Created Workshop",
        slug: "created-workshop",
        links_attributes: [{url: "https://makerworld.com/en/@createdworkshop"}]
      })
    end

    it "matches existing creator" do
      creator = create(:creator, links_attributes: [{url: "https://makerworld.com/en/@createdworkshop"}])
      expect(deserialized[:creator]).to eq creator
    end
  end

  context "without a Bambu token" do
    before do
      allow(SiteSettings).to receive(:makerworld_bambu_token).and_return(nil)
    end

    it "is metadata-only" do # rubocop:disable RSpec/MultipleExpectations
      deserializer = described_class.new(uri: uri)
      expect(deserializer.capabilities[:model_files]).to be false
      expect(deserializer.deserialize[:file_urls]).not_to include(hash_including(filename: end_with(".3mf")))
    end
  end

  context "with a Bambu token" do
    before do
      allow(SiteSettings).to receive(:makerworld_bambu_token).and_return("token-123")
      stub_request(:get, download_url)
        .with(headers: {"Authorization" => "Bearer token-123"})
        .to_return(
          status: 200,
          body: {url: signed_url, filename: "Stackable%20Painting%20Cone.3mf", name: "Profile title"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    it "adds a signed 3MF URL" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      deserializer = described_class.new(uri: uri)
      expect(deserializer.capabilities[:model_files]).to be true
      expect(deserializer.deserialize[:file_urls]).to include({
        url: signed_url,
        filename: "files/Stackable Painting Cone.3mf"
      })
    end
  end

  context "with a valid URI" do
    it "deserializes to a Model" do
      expect(described_class.new(uri: uri).capabilities[:class]).to eq Model
    end

    it "is valid for deserialization to Model" do
      expect(described_class.new(uri: uri).valid?(for_class: Model)).to be true
    end

    it "is not valid for deserialization to Creator" do
      expect(described_class.new(uri: uri).valid?(for_class: Creator)).to be false
    end

    it "is created for this URI by a link object" do # rubocop:disable RSpec/MultipleExpectations
      deserializer = create(:link, url: uri, linkable: create(:model)).deserializer
      expect(deserializer).to be_a(described_class)
      expect(deserializer).to be_valid
    end
  end
end
