require "rails_helper"

RSpec.describe DataPackage::ModelFileDeserializer do
  context "when generating an Data Package representation" do
    subject(:deserializer) { described_class.new(object) }

    let(:output) { deserializer.deserialize }
    let(:object) {
      {
        "path" => "files/test.stl",
        "mediatype" => "model/stl"
      }
    }

    it "parses filename" do
      expect(output[:filename]).to eq "files/test.stl"
    end

    it "parses media type" do
      expect(output[:mime_type]).to eq "model/stl"
    end

    it "parses notes"

    it "parses caption"

    it "parses presupported flag"

    it "parses orientation"
  end
end
