shared_examples "Follower" do
  let(:follower) { create(described_class.to_s.underscore.to_sym) }
  let(:target) { create(:model) }

  before do
    follower.follow(target)
  end

  it "shows as following" do
    expect(follower.following?(target)).to be :accepted
  end

  it "can unfollow the target" do
    follower.unfollow(target)
    expect(follower.following?(target)).to be false
  end

  it "creates a following activity" do # rubocop:todo RSpec/MultipleExpectations
    activity = follower.activities.where(action: "Follow").first
    expect(activity.actor).to eq follower.federails_actor
    expect(activity.entity).to eq target.federails_actor
  end
end
