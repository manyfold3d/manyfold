require "rails_helper"

RSpec.describe Collection do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"
  it_behaves_like "Indexable"
  it_behaves_like "IndexableWithCreatorDelegation"
  it_behaves_like "IndexableWithCollectionDelegation"
  it_behaves_like "Linkable"

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

  context "when updating a collection" do
    let(:parent) { create(:collection) }
    let(:collection) { create(:collection) }

    it "can set parent collection" do
      collection.update(collection: parent)
      expect(collection).to be_valid
    end

    it "cannot set parent collection to self" do
      collection.update(collection: collection)
      expect(collection).not_to be_valid
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
