require "rails_helper"

RSpec.describe ManyfoldApi::V0::CreatorListSerializer do
  context "when generating a JSON-LD representation" do
    subject(:serializer) { described_class.new(object) }

    before do
      create_list(:creator, 10)
    end

    let(:output) { serializer.serialize }
    let(:object) { Creator.all.page(0).per(2) }
    let(:creator) { Creator.first }

    it "uses HYDRA JSON-LD context" do
      expect(output[:@context][1]).to include({hydra: "http://www.w3.org/ns/hydra/core#"})
    end

    it "uses HYDRA collection type" do
      expect(output[:@type]).to eq "hydra:Collection"
    end

    it "has creator list URL in @id" do
      expect(output[:@id]).to eq "/creators"
    end

    it "has total item count" do
      expect(output[:totalItems]).to eq 10
    end

    it "has view object for pagination" do
      expect(output).to have_key :view
    end

    it "view object has current page in ID" do
      expect(output[:view][:@id]).to eq "/creators?page=1"
    end

    it "view object has correct type" do
      expect(output[:view][:@type]).to eq "hydra:PartialCollectionView"
    end

    it "view object includes link to first page" do
      expect(output[:view][:first]).to eq "/creators?page=1"
    end

    it "view object includes link to next page" do
      expect(output[:view][:next]).to eq "/creators?page=2"
    end

    it "view object has no link to previous page if at start" do
      expect(output[:view][:prev]).to be_nil
    end

    it "view object includes link to last page" do
      expect(output[:view][:last]).to eq "/creators?page=5"
    end

    it "produces member array" do
      expect(output[:member]).to be_an Array
    end

    it "includes ID for each creator" do
      expect(output[:member][0][:@id]).to eq "/creators/#{creator.to_param}"
    end

    it "includes name for each creator" do
      expect(output[:member][0][:name]).to eq creator.name
    end
  end
end
