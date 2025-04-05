require "rails_helper"

RSpec.describe DataPackage::ModelFileDeserializer do
  context "when generating an Data Package representation" do
    subject(:deserializer) { described_class.new(object) }

    let(:output) { deserializer.deserialize }
    let(:object) {
      {
        "path" => "files/test.stl",
        "mediatype" => "model/stl",
        "caption" => "caption goes here",
        "description" => "description goes here",
        "up" => "+y",
        "presupported" => true
      }
    }

    it "parses filename" do
      expect(output[:filename]).to eq "files/test.stl"
    end

    it "parses notes" do
      expect(output[:notes]).to eq "description goes here"
    end

    it "parses caption" do
      expect(output[:caption]).to eq "caption goes here"
    end

    it "parses presupported flag" do
      expect(output[:presupported]).to be true
    end

    it "parses orientation" do
      expect(output[:y_up]).to be true
    end
  end
end
