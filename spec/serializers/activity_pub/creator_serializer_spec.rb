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

    it "does not include icon if no avatar is set" do
      expect(ap[:icon]).to be_nil
    end

    it "includes icon if an avatar is set", :vcr do
      object.avatar_remote_url = "https://avatars.githubusercontent.com/u/152926958?s=200&v=4"
      expect(ap[:icon]).to eq({
        type: "Image",
        mediaType: "image/png",
        url: "http://localhost:3214/creators/#{object.slug}/avatar"
      })
    end
  end
end
