require "rails_helper"

RSpec.describe DataPackage::ModelDeserializer do
  context "when generating an Data Package representation" do
    subject(:deserializer) { described_class.new(object) }

    let(:output) { deserializer.deserialize }
    let(:object) do
      {
        "name" => "test-model",
        "title" => "Test Model",
        "homepage" => "https://example.com",
        "image" => "images/pic.png",
        "keywords" => ["fantasy", "wizard"],
        "description" => "caption\n\nand multiline\nnote",
        "licenses" => [
          {
            "name" => "MIT",
            "path" => "https://spdx.org/licenses/MIT.html"
          }
        ],
        "resources" => [
          {
            "path" => "files/test.stl",
            "mediatype" => "model/stl"
          }
        ],
        "contributors" => [
          {
            "title" => "Bruce Wayne",
            "path" => "http://localhost:3214/creators/bruce-wayne",
            "roles" => ["creator"]
          }
        ]
      }
    end

    it "parses name" do
      expect(output[:name]).to eq "Test Model"
    end

    it "parses caption" do
      expect(output[:caption]).to eq "caption"
    end

    it "parses notes" do
      expect(output[:notes]).to eq "and multiline\nnote"
    end

    it "parses homepage link" do
      expect(output[:links_attributes]).to include({url: "https://example.com"})
    end

    it "parses other links"

    it "parses preview image" do
      expect(output[:preview_file]).to eq "images/pic.png"
    end

    it "parses tags" do
      expect(output[:tag_list]).to eq ["fantasy", "wizard"]
    end

    it "parses license" do
      expect(output[:license]).to eq "MIT"
    end

    it "parses file data" do
      expect(output.dig(:model_files, 0, :filename)).to eq "files/test.stl"
    end

    it "parses creator ID if creator exists" do
      creator = create(:creator, name: "Bruce Wayne")
      expect(output.dig(:creator, :id)).to eq creator.id
    end

    it "parses creator link if creator doesn't exist" do
      expect(output.dig(:creator, :links_attributes, 0, :url)).to eq "http://localhost:3214/creators/bruce-wayne"
    end

    it "parses collection"
  end
end
