require "rails_helper"

RSpec.describe ActivityPub::CollectionSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) { create(:collection, :public) }

    it_behaves_like "GenericSerializer"

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "Collection"
    end
  end
end
