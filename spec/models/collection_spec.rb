require "rails_helper"

RSpec.describe Collection do
  it_behaves_like "Followable"
  it_behaves_like "Talkative"
  it_behaves_like "Commentable"
  it_behaves_like "Caber::Object"
  it_behaves_like "Sluggable"
  it_behaves_like "Indexable"
  it_behaves_like "IndexableWithCreatorDelegation"
  it_behaves_like "IndexableWithCollectionDelegation"
  it_behaves_like "Linkable"

  it "is not valid if name is too long" do
    expect(build(:collection, name: SecureRandom.alphanumeric(226))).not_to be_valid
  end

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

    it "can set preview model to something in this collection" do
      model = create(:model, collections: [collection])
      collection.update(preview_model: model)
      expect(collection).to be_valid
    end

    it "can't set preview model to something not in this collection" do
      model = create(:model)
      collection.update(preview_model: model)
      expect(collection).not_to be_valid
    end

    it "nullifies preview model if deleted" do
      model = create(:model)
      collection.update(preview_model: model)
      model.destroy!
      expect(collection.reload.preview_model).to be_nil
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

  context "when navigating collection hierarchy with tree_down" do
    let(:root) { create(:collection) }
    let(:branch) { create(:collection, collection: root) }
    let(:leaf) { create(:collection, collection: branch) }
    let(:other) { create(:collection) }

    it "includes self" do
      expect(described_class.tree_down(branch.id)).to include branch
    end

    it "returns child collections" do # rubocop:todo RSpec/MultipleExpectations
      descendants = described_class.tree_down(branch.id)
      expect(descendants).to include leaf
      expect(descendants.count).to eq 2
    end

    it "returns grandchild collections" do # rubocop:todo RSpec/MultipleExpectations
      descendants = described_class.tree_down(root.id)
      expect(descendants).to include branch
      expect(descendants).to include leaf
      expect(descendants.count).to eq 3
    end

    it "does not return unrelated collections" do
      descendants = described_class.tree_down(root.id)
      expect(descendants).not_to include other
    end

    it "can query multiple collections at once" do # rubocop:todo RSpec/MultipleExpectations
      descendants = described_class.tree_down([branch.id, other.id])
      expect(descendants).to include branch
      expect(descendants).to include leaf
      expect(descendants).to include other
      expect(descendants.count).to eq 3
    end
  end

  context "when serializing JSON fields", :after_first_run do
    let(:collection) { create(:collection, :with_cover) }

    before do
      create(:library)
    end

    [
      :cover_data
    ].each do |field|
      it "deserializes #{field.to_s.humanize} correctly" do
        expect(collection.reload.send(field)).to be_a Hash
      end
    end
  end
end
