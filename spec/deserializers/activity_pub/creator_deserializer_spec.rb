require "rails_helper"

RSpec.describe ActivityPub::CreatorDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(actor) }

    let(:actor) { create(:actor, :distant, :f3di_creator) }
    let(:output) { deserializer.create! }

    it_behaves_like "GenericDeserializer"
  end
end
