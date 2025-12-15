require "rails_helper"

RSpec.describe Creator do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"
  it_behaves_like "Indexable"
  it_behaves_like "Linkable"

  context "when generating an ActivityStreams representation" do
    subject(:creator) { create(:creator, :public) }

    let(:ap) { creator.to_activitypub_object }

    it "includes concrete type" do
      expect(ap[:"f3di:concreteType"]).to eq "Creator"
    end

    it "includes attributionDomain" do
      expect(ap[:attributionDomains]).to contain_exactly("localhost:3214")
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

  context "when serializing JSON fields", :after_first_run do
    let(:creator) { create(:creator, :with_avatar, :with_banner) }

    before do
      create(:library)
    end

    [
      :avatar_data,
      :banner_data
    ].each do |field|
      it "deserializes #{field.to_s.humanize} correctly" do
        expect(creator.reload.send(field)).to be_a Hash
      end
    end
  end
end
