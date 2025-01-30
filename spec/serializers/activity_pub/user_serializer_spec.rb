require "rails_helper"

RSpec.describe ActivityPub::UserSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) { create(:contributor) }

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "User"
    end
  end
end
