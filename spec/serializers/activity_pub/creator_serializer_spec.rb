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

    let(:ap) { serializer.serialize }

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "Creator"
    end

    it "includes attributionDomain" do
      expect(ap[:attributionDomains]).to eq ["localhost:3214"]
    end

    it "includes caption in summary" do
      expect(ap[:summary]).to include creator.caption
    end

    it "includes notes in content" do
      expect(ap[:content]).to include creator.notes
    end

    it "includes links as attachments" do
      expect(ap[:attachment]).to include({type: "Link", href: "http://example.com"})
    end
  end
end
