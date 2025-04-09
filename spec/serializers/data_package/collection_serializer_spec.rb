require "rails_helper"

RSpec.describe DataPackage::CollectionSerializer do
  context "when generating an Data Package representation" do
    subject(:serializer) { described_class.new(object) }

    let(:output) { serializer.serialize }
    let(:object) {
      create(:collection,
        links_attributes: [{url: "https://example.com"}],
        caption: "caption goes here",
        notes: "notes go here")
    }

    it "includes name" do
      expect(output[:title]).to eq object.name
    end

    it "includes path" do
      expect(output[:path]).to eq "http://localhost:3214/collections/#{object.to_param}"
    end

    context "with extension fields" do
      it "includes links" do
        expect(output.dig(:links, 0, :path)).to be_present
      end

      it "includes caption" do
        expect(output[:caption]).to eq object.caption
      end

      it "includes notes" do
        expect(output[:description]).to eq object.notes
      end
    end
  end
end
