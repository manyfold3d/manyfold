require "rails_helper"

RSpec.describe ActivityPub::ModelSerializer do
  context "when generating an ActivityStreams representation" do
    subject(:serializer) { described_class.new(object) }

    let(:ap) { serializer.serialize }
    let(:object) {
      c = create(:model, :with_tags)
      c.grant_permission_to "view", nil
      c
    }

    it_behaves_like "GenericSerializer"

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "3DModel"
    end

    it "includes right number of tags" do
      expect(ap[:tag].count).to eq 2
    end

    it "has valid tag structure" do
      expect(ap[:tag].first).to eq({
        type: "Hashtag",
        name: "#Tag0",
        href: "http://localhost:3214/models?tag=tag_0"
      })
    end
  end
end
