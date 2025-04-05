require "rails_helper"

RSpec.describe DataPackage::ModelFileSerializer do
  context "when generating an Data Resource representation" do
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
      expect(output[:name]).to eq "test-model"
    end

    it "includes path" do
      expect(output[:path]).to eq "files/test model.stl"
    end

    it "includes media type" do
      expect(output[:mediatype]).to eq "model/stl"
    end

    context "with extension fields" do
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
end
