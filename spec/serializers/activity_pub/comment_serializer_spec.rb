require "rails_helper"

RSpec.describe ActivityPub::CommentSerializer do
  subject(:serializer) { described_class.new(comment) }

  let(:ap) { serializer.serialize }

  context "when commenting on something with tags" do
    let(:model) { create(:model, tag_list: ["tag"]) }
    let(:comment) { create(:comment, commentable: model, commenter: model) }

    it "adds tag list to a trailing paragraph in content" do
      expect(ap["content"]).to include "<p role=\"list\">"
    end

    it "adds tag link" do
      expect(ap["content"]).to include "<a role=\"listitem\" href=\"http://localhost:3214/models?tag=tag\" class=\"mention hashtag\" rel=\"tag\">#Tag</a>"
    end
  end

  context "when commenting on something with no tags" do
    let(:model) { create(:model, tag_list: nil) }
    let(:comment) { create(:comment, commentable: model, commenter: model) }

    it "doesn't include tag list paragraph" do
      expect(ap["content"]).not_to include "<p role=\"list\">"
    end
  end

  context "when a public creator comments on a public model" do
    let(:creator) { create(:creator, :public) }
    let(:model) { create(:model, :public) }
    let(:comment) { create(:comment, commenter: creator, commentable: model) }

    it "includes public collection in to" do
      expect(serializer.to).to include "https://www.w3.org/ns/activitystreams#Public"
    end

    it "includes model followers collection in cc" do
      expect(serializer.cc).to include model.federails_actor.followers_url
    end

    it "includes creator followers collection in cc" do
      expect(serializer.cc).to include creator.federails_actor.followers_url
    end
  end

  context "when a public creator comments on a public model in a public collection" do
    let(:creator) { create(:creator, :public) }
    let(:collection) { create(:collection, :public) }
    let(:model) { create(:model, :public, collection: collection) }
    let(:comment) { create(:comment, commenter: creator, commentable: model) }

    it "includes collection followers collection in cc" do
      expect(serializer.cc).to include collection.federails_actor.followers_url
    end
  end

  context "when a public creator comments on a public collection" do
    let(:creator) { create(:creator, :public) }
    let(:collection) { create(:collection, :public) }
    let(:comment) { create(:comment, commenter: creator, commentable: collection) }

    it "includes collection followers collection in cc" do
      expect(serializer.cc).to include collection.federails_actor.followers_url
    end
  end

  context "when a public collection comments on itself with a public creator" do
    let(:creator) { create(:creator, :public) }
    let(:collection) { create(:collection, :public, creator: creator) }
    let(:comment) { create(:comment, commenter: collection, commentable: collection) }

    it "includes creator followers collection in cc" do
      expect(serializer.cc).to include creator.federails_actor.followers_url
    end
  end

  context "when a public creator comments on a public collection that is itself inside a public collection" do
    let(:creator) { create(:creator, :public) }
    let(:parent_collection) { create(:collection, :public) }
    let(:collection) { create(:collection, :public, collection: parent_collection) }
    let(:comment) { create(:comment, commenter: creator, commentable: collection) }

    it "includes parent collection followers collection in cc" do
      expect(serializer.cc).to include parent_collection.federails_actor.followers_url
    end
  end
end
