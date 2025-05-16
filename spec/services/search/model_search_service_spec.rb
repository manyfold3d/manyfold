require "rails_helper"

RSpec.describe Search::ModelSearchService do
  subject(:result) { described_class.new(scope).search(query) }

  let(:scope) { Model }

  before do
    create(:model, name: "cat in the hat")
    create(:model, name: "hat on the cat")
    create(:model, name: "bat on a mat")
    create(:model, name: "bat on a hat")
  end

  context "with a simple query" do
    let(:query) { "cat" }

    it "returns results containing the term" do
      expect(result.count).to eq 2
    end
  end

  context "with a multiword query" do
    let(:query) { "cat in the hat" }

    it "returns results containing any of the terms" do
      expect(result.count).to eq 3
    end
  end

  context "with a quoted query" do
    let(:query) { '"the hat"' }

    it "returns results containing the exact term" do
      expect(result.count).to eq 1
    end
  end
end
