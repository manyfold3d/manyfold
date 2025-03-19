require "rails_helper"

RSpec.describe JsonLd::ModelListSerializer do
  context "when generating a JSON-LD representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) { Model.all.page(0) }
    let!(:model) { create(:model) }

    it "uses HYDRA JSON-LD context" do
      expect(output[:@context]).to eq "http://www.w3.org/ns/hydra/context.jsonld"
    end

    it "uses HYDRA collection type" do
      expect(output[:@type]).to eq "Collection"
    end

    it "has total item count" do
      expect(output[:totalItems]).to eq 1
    end

    it "produces member array" do
      expect(output[:member]).to be_an Array
    end

    it "includes ID for each model" do
      expect(output[:member][0][:@id]).to eq "/models/#{model.to_param}"
    end

    it "includes name for each model" do
      expect(output[:member][0][:name]).to eq model.name
    end
  end
end
