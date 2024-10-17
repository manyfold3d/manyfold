require "rails_helper"

RSpec.describe Comment do
  context "with public commenter and commentable" do
    let(:commenter) do
      c = create(:creator)
      c.grant_permission_to "view", nil
      c
    end
    let(:commentable) do
      m = create(:model, creator: commenter, tag_list: "tag one, tag2")
      m.grant_permission_to "view", nil
      m
    end
    let!(:comment) { create(:comment, commenter: commenter, commentable: commentable, sensitive: true) }

    it "posts a Federails Activity on creation" do # rubocop:disable RSpec/MultipleExpectations
      expect { create(:comment, commenter: commenter, commentable: commentable) }.to change(Federails::Activity, :count).by(1)
      expect(Federails::Activity.last.action).to eq "Create"
    end

    it "posts a Federails Activity on update" do # rubocop:disable RSpec/MultipleExpectations
      expect { comment.update(comment: "test") }.to change(Federails::Activity, :count).by(1)
      expect(Federails::Activity.last.action).to eq "Update"
    end

    it "has a federated_url method" do
      expect(comment.federated_url).to eq "http://localhost:3214/models/#{commentable.public_id}/comments/#{comment.public_id}"
    end

    context "when serializing to an ActivityPub Note" do
      let(:ap_object) { comment.to_activitypub_object }

      it "creates a Note" do
        expect(ap_object[:type]).to eq "Note"
      end

      it "includes content" do
        expect(ap_object[:content]).to be_present
      end

      it "includes id" do
        expect(ap_object[:id]).to eq comment.federated_url
      end

      it "includes commentable ID in context" do
        expect(ap_object[:context]).to eq "http://localhost:3214/models/#{commentable.public_id}"
      end

      it "includes publication time" do
        expect(ap_object[:published]).to be_present
      end

      it "includes sensitive flag" do
        expect(ap_object[:sensitive]).to be true
      end

      it "includes attribution" do
        expect(ap_object[:attributedTo]).to eq commenter.actor.federated_url
      end

      it "includes to field" do
        expect(ap_object[:to]).to include "https://www.w3.org/ns/activitystreams#Public"
      end

      it "includes cc field" do
        expect(ap_object[:cc]).to include commenter.actor.followers_url
      end

      it "includes tags appended to content" do
        {"tag+one": "#TagOne", tag2: "#Tag2"}.each_pair do |link, hashtag|
          expect(ap_object[:content]).to include %(<a href="http://localhost:3214/models?tag=#{link}" class="mention hashtag" rel="tag">#{hashtag}</a>)
        end
      end

      it "includes tags as mentions" do # rubocop:disable RSpec/ExampleLength
        {"tag+one": "#TagOne", tag2: "#Tag2"}.each_pair do |link, hashtag|
          expect(ap_object[:tag]).to include(
            type: "Hashtag",
            href: "http://localhost:3214/models?tag=#{link}",
            name: hashtag
          )
        end
      end
    end
  end

  context "with non-public commenter" do
    let(:commenter) { create(:creator) }
    let(:commentable) do
      m = create(:model, creator: commenter)
      m.grant_permission_to "view", nil
      m
    end

    it "Does not post a Federails Activity on creation" do
      expect { create(:comment, commenter: commenter, commentable: commentable) }.not_to change(Federails::Activity, :count)
    end

    it "does not have a federated_url" do
      comment = create(:comment, commenter: commenter, commentable: commentable)
      expect(comment.federated_url).to be_nil
    end
  end

  context "with non-public commentable" do
    let(:commenter) do
      c = create(:creator)
      c.grant_permission_to "view", nil
      c
    end
    let(:commentable) { create(:model, creator: commenter) }

    it "Does not post a Federails Activity on creation" do
      expect { create(:comment, commenter: commenter, commentable: commentable) }.not_to change(Federails::Activity, :count)
    end

    it "does not have a federated_url" do
      comment = create(:comment, commenter: commenter, commentable: commentable)
      expect(comment.federated_url).to be_nil
    end
  end
end
