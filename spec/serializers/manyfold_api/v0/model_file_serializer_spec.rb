require "rails_helper"

RSpec.describe ManyfoldApi::V0::ModelFileSerializer do
  context "when generating a JSON-LD representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) {
      create(:model_file,
        filename: "files/test model.stl",
        presupported: true,
        y_up: true,
        caption: "caption goes here",
        notes: "description goes here")
    }

    it "includes name" do
      expect(output[:name]).to eq "Test Model"
    end

    it "includes URL for content" do
      expect(output[:contentUrl]).to eq "http://localhost:3214/models/#{object.model.to_param}/raw/files/test%20model.stl"
    end

    it "includes notes" do
      expect(output[:description]).to eq "description goes here"
    end

    it "includes caption" do
      expect(output[:caption]).to eq "caption goes here"
    end

    it "includes presupported flag" do
      expect(output[:presupported]).to be true
    end

    it "includes orientation" do
      expect(output[:up]).to eq "+y"
    end
  end
end
