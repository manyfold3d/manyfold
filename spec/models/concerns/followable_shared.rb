shared_examples "Followable" do
  context "when being followed" do
    let(:follower) { create(:user) }
    let(:target) { create(described_class.to_s.underscore.to_sym) }

    before do
      follower.follow(target)
    end

    it "shows as being followed by follower" do
      expect(target.followed_by?(follower)).to be true
    end

    it "gets follower count" do
      expect(target.followers.count).to eq 1
    end
  end
end
