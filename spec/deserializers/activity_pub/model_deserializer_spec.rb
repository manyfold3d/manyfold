require "rails_helper"

RSpec.describe ActivityPub::ModelDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(actor) }

    before do
      create(:library)
    end

    let(:actor) { create(:actor, :distant, :f3di_model) }
    let(:output) { deserializer.create! }

    it_behaves_like "GenericDeserializer"

    it "sets license from licenseId" do
      expect(output.license).to eq "MIT"
    end

    it "sets correct tags" do
      expect(output.tag_list).to contain_exactly("Hash Tag", "Wizard")
    end
  end
end
