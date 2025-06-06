require "rails_helper"

RSpec.describe Collection do
  it_behaves_like "Followable"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"

  context "when creating a collection" do
    let(:model) { create(:collection) }

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
        collection.grant_permission_to "view", nil
      }.to have_enqueued_job(Activity::CollectionPublishedJob).once
    end
  end
end
