require "rails_helper"

RSpec.describe ActivityPub::ModelDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(actor) }

    before do
      create(:library)
    end

    let(:actor) { create(:model_actor) }
    let(:output) { deserializer.create! }

    it_behaves_like "GenericDeserializer"

    it "sets license from licenseId" do
      expect(output.license).to eq "MIT"
    end

    it "sets correct tags" do
      expect(output.tag_list).to eq ["hash tag", "wizard"]
    end
  end
end
