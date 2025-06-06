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
end
