require "rails_helper"

RSpec.describe ActivityPub::CommentSerializer do
  subject(:serializer) { described_class.new(comment) }

  let(:ap) { serializer.serialize }

  context "when a user comments on a public model", :after_first_run do
    let(:user) { create(:user) }
    let(:model) { create(:model) }
    let(:comment) { create(:comment, commentable: model, commenter: user) }

    it "includes model's canonical URL as context" do
      expect(ap["context"]).to eq "http://localhost:3214/models/#{model.to_param}"
    end

    it "is posted as a reply to the model" do
      expect(ap["inReplyTo"]).to include model.federails_actor.federated_url
    end

    it "has user's actor URL in atributedTo" do
      expect(ap["attributedTo"]).to eq user.federails_actor.federated_url
    end

    it "is a Note" do
      expect(ap["type"]).to eq "Note"
    end

    it "is not a f3di compatibility note" do
      expect(ap["f3di:compatibilityNote"]).to be false
    end
  end

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
