require "rails_helper"

RSpec.describe JsonLd::ModelListSerializer do
  context "when generating a JSON-LD representation" do
    subject(:serializer) { described_class.new(object) }

    before do
      create_list(:model, 10)
    end

    let(:output) { serializer.serialize }
    let(:object) { Model.all.page(0).per(2) }
    let(:model) { Model.first }

    it "uses HYDRA JSON-LD context" do
      expect(output[:@context]).to eq "http://www.w3.org/ns/hydra/context.jsonld"
    end

    it "uses HYDRA collection type" do
      expect(output[:@type]).to eq "Collection"
    end

    it "has model list URL in @id" do
      expect(output[:@id]).to eq "/models"
    end

    it "has total item count" do
      expect(output[:totalItems]).to eq 10
    end

    it "has view object for pagination" do
      expect(output).to have_key :view
    end

    it "view object has current page in ID" do
      expect(output[:view][:@id]).to eq "/models?page=1"
    end

    it "view object has correct type" do
      expect(output[:view][:@type]).to eq "PartialCollectionView"
    end

    it "view object includes link to first page" do
      expect(output[:view][:first]).to eq "/models?page=1"
    end

    it "view object includes link to next page" do
      expect(output[:view][:next]).to eq "/models?page=2"
    end

    it "view object has no link to previous page if at start" do
      expect(output[:view][:prev]).to be_nil
    end

    it "view object includes link to last page" do
      expect(output[:view][:last]).to eq "/models?page=5"
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
