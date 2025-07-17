require "rails_helper"

RSpec.describe UpdateMetadataFromLinkJob do
  subject(:job) { described_class.new }

  before { create(:library) }

  context "when importing a model" do
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

    context "with an existing creator" do
      let!(:creator) { create(:creator, slug: "batman") }

      it "does not make a new creator" do
        expect { described_class.perform_now(link: link) }.not_to change(Creator, :count)
      end

      it "sets creator" do
        described_class.perform_now(link: link)
        expect(model.reload.creator).to eq creator
      end
    end

    it "creates a new creator if nothing matches" do
      expect { described_class.perform_now(link: link) }.to change(Creator, :count).by(1)
    end
  end
end
