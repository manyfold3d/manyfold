shared_examples "Follower" do
  let(:follower) { create(described_class.to_s.underscore.to_sym) }
  let(:target) { create(:model) }

  before do
    follower.follow(target)
  end

  it "shows as following" do
    expect(follower.following?(target)).to be true
  end

  it "can unfollow the target" do
    follower.unfollow(target)
    expect(follower.following?(target)).to be false
  end

  it "creates a following activity" do # rubocop:todo RSpec/MultipleExpectations
    activity = follower.activities.first
    expect(activity.action).to eq "Create"
    expect(activity.entity).to eq follower.following_follows.first
  end
end
