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

  context "when being created" do
    before do
      create(:admin)
    end

    it "posts an activity" do
      entity = create(described_class.to_s.underscore.to_sym)
      expect(Federails::Activity.where(entity: entity.actor, action: "Create").count).to eq 1
    end
  end

  context "when being updated" do
    let!(:entity) { create(described_class.to_s.underscore.to_sym) }

    before do
      create(:admin)
    end

    it "posts an activity after update" do
      entity.update caption: "test"
      expect(Federails::Activity.where(entity: entity.actor, action: "Update").count).to eq 1
    end

    it "doesn't post an activity after update if there's already been one recently" do
      entity.update caption: "change"
      entity.update caption: "change again"
      expect(Federails::Activity.where(entity: entity.actor, action: "Update").count).to eq 1
    end
  end
end
