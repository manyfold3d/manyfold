shared_examples "Indexable" do
  [true, false].each do |state|
    context "with default indexing set to #{state}" do
      before do
        allow(SiteSettings).to receive_messages(default_indexable: state, default_ai_indexable: state)
      end

      let(:object) { create(described_class.name.downcase.to_sym) }

      it "defaults to inherit" do
        expect(object.indexable).to be_nil
      end

      it "uses default indexable value" do
        expect(object.indexable?).to be state
      end

      it "uses default AI indexable value" do
        expect(object.ai_indexable?).to be state
      end
    end
  end

  context "when setting its own indexing preference" do
    before do
      allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: true)
    end

    let(:object) { create(described_class.name.downcase.to_sym, indexable: "no", ai_indexable: "no") }

    it "overrides default indexing" do
      expect(object.indexable?).to be false
    end

    it "overrides default ai indexing" do
      expect(object.ai_indexable?).to be false
    end
  end
end

shared_examples "IndexableWithCreatorDelegation" do
  context "when delegating to creator indexing preference" do
    before do
      allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: true)
    end

    let(:object) {
      create(described_class.name.downcase.to_sym,
        creator: create(:creator, indexable: "no", ai_indexable: "no"))
    }

    it "overrides default indexing" do
      expect(object.indexable?).to be false
    end

    it "overrides default ai indexing" do
      expect(object.ai_indexable?).to be false
    end
  end
end

shared_examples "IndexableWithCollectionDelegation" do
  context "when delegating to collection indexing preference" do
    before do
      allow(SiteSettings).to receive_messages(default_indexable: true, default_ai_indexable: true)
    end

    let(:object) {
      create(described_class.name.downcase.to_sym,
        collection: create(:collection, indexable: "no", ai_indexable: "no"))
    }

    it "overrides default indexing" do
      expect(object.indexable?).to be false
    end

    it "overrides default ai indexing" do
      expect(object.ai_indexable?).to be false
    end
  end
end
