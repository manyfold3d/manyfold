require "rails_helper"

RSpec.describe DataPackage::ModelFileSerializer do
  context "when generating an Data Resource representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) { create(:model_file, filename: "files/test model.stl") }

    it "includes name" do
      expect(output[:name]).to eq "test-model"
    end

    it "includes path" do
      expect(output[:path]).to eq "files/test model.stl"
    end

    it "includes media type" do
      expect(output[:mediatype]).to eq "model/stl"
    end
  end
end
