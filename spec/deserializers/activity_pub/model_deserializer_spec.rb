require "rails_helper"

RSpec.describe ActivityPub::ModelDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(actor) }

    let(:actor) { create(:model_actor) }
    let(:output) { deserializer.deserialize }

    it_behaves_like "GenericDeserializer"

    it "sets license from licenseId" do
      expect(output.license).to eq "MIT"
    end
  end
end
