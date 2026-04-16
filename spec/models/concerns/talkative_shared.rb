shared_examples "Talkative" do
  context "when being created" do
    before do
      create(:admin)
    end

    it "posts an activity" do
      expect {
        create(described_class.to_s.underscore.to_sym)
      }.to change { Federails::Activity.where(action: "Create").count }.from(0).to(1)
    end

    it "posts activity for the correct actor" do
      entity = create(described_class.to_s.underscore.to_sym)
      expect(Federails::Activity.where(action: "Create").last.entity).to eq entity.federails_actor
    end
  end

  context "when updating a model that was created a while ago" do
    let!(:entity) { create(described_class.to_s.underscore.to_sym, created_at: 1.hour.ago, updated_at: 1.hour.ago) }

    it "posts an activity after update" do
      expect {
        entity.update caption: "test"
      }.to change { Federails::Activity.where(entity: entity.federails_actor, action: "Update").count }.from(0).to(1)
    end

    it "doesn't post an activity after update if there's already been one recently" do
      entity.update caption: "change"
      expect {
        entity.update caption: "change again"
      }.not_to change { Federails::Activity.where(entity: entity.federails_actor, action: "Update").count }
    end
  end

  context "when updating a model that was just created" do
    let!(:entity) { create(described_class.to_s.underscore.to_sym) }

    it "doesn't post an activity after update" do
      expect {
        entity.update caption: "test"
      }.not_to change { Federails::Activity.where(entity: entity.federails_actor, action: "Update").count }
    end
  end
end
