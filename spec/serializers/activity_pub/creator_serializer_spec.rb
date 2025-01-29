require "rails_helper"

RSpec.describe ActivityPub::CreatorSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) {
      c = create(:creator)
      c.grant_permission_to "view", nil
      c
    }

    it_behaves_like "GenericSerializer"

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "Creator"
    end

    it "includes attributionDomain" do
      expect(ap[:attributionDomains]).to eq ["localhost:3214"]
    end
  end
end
