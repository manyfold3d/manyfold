require "rails_helper"

RSpec.describe Collection do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"

  context "when creating a collection" do
    it "doesn't queue any activity jobs" do
      expect {
        create(:collection)
      }.not_to have_enqueued_job(Activity::CollectionPublishedJob)
    end

    it "queues publish activity job if the collection was created as public" do
      expect {
        create(:collection, :public)
      }.to have_enqueued_job(Activity::CollectionPublishedJob).once
    end

    it "queues publish activity job if the collection created private but then made public" do
      collection = create(:collection)
      expect {
        collection.update!(caber_relations_attributes: [{subject: nil, permission: "view"}])
      }.to have_enqueued_job(Activity::CollectionPublishedJob).once
    end
  end

  context "when making a collection public" do
    let!(:collection) { create(:collection) }

    before do
      collection.update(
        caber_relations_attributes: [{subject: nil, permission: "view"}],
        creator: create(:creator),
        collection: create(:collection)
      )
      collection.validate
    end

    it "makes creator public automatically" do
      expect(collection.creator).to be_public
    end

    it "requires collection to be public if set" do
      expect(collection.errors[:collection]).to include "must be public"
    end

    it "doesn't make collection public if validation failed" do
      expect(collection.reload.public?).to be false
    end
  end
end
