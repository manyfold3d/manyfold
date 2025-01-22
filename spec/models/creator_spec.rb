require "rails_helper"

RSpec.describe Creator do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"

  context "when generating an ActivityStreams representation" do
    subject(:creator) { create(:creator) }

    let(:ap) { creator.to_activitypub_object }

    it "includes concrete type" do
      expect(ap[:concreteType]).to eq "Creator"
    end

    it "includes attributionDomain" do
      expect(ap[:attributionDomains]).to eq ["localhost:3214"]
    end

    it "includes caption in summary" do
      expect(ap[:summary]).to include creator.caption
    end

    it "includes notes in summary" do
      expect(ap[:summary]).to include creator.notes
    end
  end
end
