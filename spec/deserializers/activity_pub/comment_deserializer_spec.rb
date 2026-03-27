require "rails_helper"

RSpec.describe ActivityPub::CommentDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(object) }

    let(:model) { create(:model, :public) }
    let(:output) { deserializer.create! }

    context "with a plain Note from another server" do
      let(:object) { build(:note) }

      it "is not handled" do
        expect(described_class.can_handle?(object)).to be false
      end
    end

    context "with a Note from another server replying to a known system comment", vcr: {cassette_name: "ActivityPub_CreatorDeserializer/success"} do
      let!(:system_comment) { create(:comment, commenter: model, commentable: model, system: true) }
      let(:object) { build(:note, inReplyTo: system_comment.federated_url, content: "<h1>Nice model!</h1>") }

      it "is handled" do
        expect(described_class.can_handle?(object)).to be true
      end

      it "creates a new Comment" do
        expect { deserializer.create! }.to change(Comment, :count).by(1)
      end

      it "parses correct commenter" do
        comment = deserializer.create!
        expect(comment.federails_actor.name).to eq "Manyfold"
      end

      it "parses correct commentable item" do
        comment = deserializer.create!
        expect(comment.commentable).to eq model
      end

      it "stores the sanitized comment" do
        comment = deserializer.create!
        expect(comment.comment).to eq "Nice model!"
      end
    end

    context "with a Note from another server replying to a known model URL", vcr: {cassette_name: "ActivityPub_CreatorDeserializer/success"} do
      let(:object) { build(:note, inReplyTo: model.federails_actor.federated_url) }

      it "is handled" do
        expect(described_class.can_handle?(object)).to be true
      end

      it "parses correct commentable item" do
        comment = deserializer.create!
        expect(comment.commentable).to eq model
      end
    end

    context "with a compatibility Note" do
      let(:object) { build(:note, "f3di:compatibilityNote": "true") }

      it "is not handled" do
        expect(described_class.can_handle?(object)).to be false
      end
    end
  end
end
