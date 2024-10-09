require "rails_helper"

RSpec.describe Activity::CreatorAddedModelJob do
  let(:creator) { create(:creator) }
  let(:model) { create(:model, creator: creator, tag_list: "tag1, tag2") }

  it "adds a comment" do
    expect { described_class.new.perform(model.id) }.to change(Comment, :count).by(1)
  end

  it "ends up queueing an ActivityPub publish job" do
    expect { described_class.new.perform(model.id) }.to have_enqueued_job Federails::NotifyInboxJob
  end

  context "with a comment" do
    subject(:comment) { model.comments.first }

    before do
      described_class.new.perform(model.id)
    end

    it "sets creator as author" do
      expect(comment.commenter).to eq creator
    end

    it "sets model as the subject" do
      expect(comment.commentable).to eq model
    end

    it "marks comment as a system comment" do
      expect(comment.system).to be true
    end

    it "includes model name in text" do
      expect(comment.comment).to include model.name
    end

    it "includes tags in text as hashtags" do
      model.tag_list.each do |tag|
        expect(comment.comment).to include "##{tag}"
      end
    end

    it "includes URL in text" do
      expect(comment.comment).to include "http://localhost:3214/models/#{model.public_id}"
    end
  end
end
