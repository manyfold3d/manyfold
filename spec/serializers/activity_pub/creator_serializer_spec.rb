require "rails_helper"

RSpec.describe ActivityPub::CreatorSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) { create(:creator, :public) }

    it_behaves_like "GenericActivityPubSerializer"

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "Creator"
    end

    it "includes attributionDomain" do
      expect(ap[:attributionDomains]).to contain_exactly("localhost:3214")
    end
  end
end
