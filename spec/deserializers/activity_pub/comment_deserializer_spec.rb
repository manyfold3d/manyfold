require "rails_helper"

RSpec.describe ActivityPub::CommentDeserializer do
  context "when parsing an ActivityStreams representation" do
    subject(:deserializer) { described_class.new(object) }

    let(:model) { create(:model, :public) }
    let(:output) { deserializer.create! }

    context "with a plain Note from another server" do
      let(:object) { {"type" => "Note"} }

      it "is not handled" do
        expect(described_class.can_handle?(object)).to be false
      end
    end

    context "with a Note from another server replying to a known system comment" do
      let(:system_comment) { create(:comment, commenter: model, commentable: model, system: true) }
      let(:object) { {"type" => "Note", "inReplyTo" => system_comment.federated_url} }

      it "is handled" do
        expect(described_class.can_handle?(object)).to be true
      end
    end

    context "with a Note from another server replying to a known model URL" do
      let(:object) { {"type" => "Note", "inReplyTo" => model.federails_actor.federated_url} }

      it "is handled" do
        expect(described_class.can_handle?(object)).to be true
      end
    end

    context "with a compatibility Note" do
      let(:object) { {"type" => "Note", "extensions" => {"f3di:comptibilityNote" => "true"}} }

      it "is not handled" do
        expect(described_class.can_handle?(object)).to be false
      end
    end
  end
end
