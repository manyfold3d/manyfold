shared_examples "Likeable" do
  let(:user) { create(:user) }
  let(:thing) { create(described_class.to_s.underscore.to_sym, :public) }

  it "changes like count when added to a list" do
    expect { user.liked_list.models << thing }.to change(thing, :like_count).by(1)
  end

  context "with federation", :federated do
    let(:actor) { create(:actor, :distant) }

    it "includes remote Like activities in count" do # rubocop:todo RSpec/ExampleLength
      activity = {
        "action" => "Like",
        "actor" => actor.federated_url,
        "object" => thing.to_activitypub_object.merge("id" => thing.federails_actor.federated_url)
      }
      expect {
        ActivityPub::LikeActivityHandler.handle_like_activity(activity)
      }.to change { thing.reload.like_count }.from(0).to(1)
    end

    it "includes Likes on system comments in count" do # rubocop:todo RSpec/ExampleLength
      comment = create(:comment, commentable: thing, system: true, commenter: thing)
      activity = {
        "action" => "Like",
        "actor" => actor.federated_url,
        "object" => comment.to_activitypub_object
      }
      expect {
        ActivityPub::LikeActivityHandler.handle_like_activity(activity)
      }.to change { thing.reload.like_count }.from(0).to(1)
    end

    it "ignores Likes on non-system comments in count" do # rubocop:todo RSpec/ExampleLength
      comment = create(:comment, commentable: thing, system: false, commenter: thing)
      activity = {
        "action" => "Like",
        "actor" => actor.federated_url,
        "object" => comment.to_activitypub_object
      }
      expect {
        ActivityPub::LikeActivityHandler.handle_like_activity(activity)
      }.not_to change { thing.reload.like_count }
    end

    it "ignores local Like activities in count" do # rubocop:todo RSpec/ExampleLength
      activity = {
        "action" => "Like",
        "actor" => user.federails_actor.federated_url,
        "object" => thing.to_activitypub_object.merge("id" => thing.federails_actor.federated_url)
      }
      expect {
        ActivityPub::LikeActivityHandler.handle_like_activity(activity)
      }.not_to change { thing.reload.like_count }
    end
  end
end
