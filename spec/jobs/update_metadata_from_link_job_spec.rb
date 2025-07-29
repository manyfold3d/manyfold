require "rails_helper"

RSpec.describe UpdateMetadataFromLinkJob do
  subject(:job) { described_class.new }

  before { create(:library) }

  context "when updating a model" do
    let(:model) { create(:model, links_attributes: [{url: "https://example.com"}]) }
    let(:deserializer) {
      deserializer = instance_double(Integrations::Thingiverse::ModelDeserializer)
      allow(deserializer).to receive(:deserialize).and_return({creator_attributes: {
        name: "Bruce Wayne",
        slug: "batman"
      }})
      deserializer
    }
    let(:link) do
      link = model.links.first
      allow(link).to receive(:deserializer).and_return(deserializer)
      link
    end

    it "creates a new creator if nothing matches" do
      expect { described_class.perform_now(link: link) }.to change(Creator, :count).by(1)
    end
  end

  context "when link fetch fails" do
    let(:model) { create(:model, links_attributes: [{url: "https://example.com"}]) }
    let(:deserializer) {
      deserializer = instance_double(Integrations::Thingiverse::ModelDeserializer)
      allow(deserializer).to receive(:deserialize).and_raise(Faraday::ResourceNotFound.new("not found"))
      deserializer
    }
    let(:link) do
      link = model.links.first
      allow(link).to receive(:deserializer).and_return(deserializer)
      link
    end

    it "logs a problem on the link" do
      described_class.perform_now(link: link)
      expect(Problem.last.problematic).to eq link
    end

    it "include failure message in problem note" do
      described_class.perform_now(link: link)
      expect(Problem.last.note).to eq "not found"
    end
  end
end
