require "rails_helper"

RSpec.describe Search::ModelSearchService do
  subject(:service) { described_class.new(Model) }

  context "with a range of models" do
    before do
      seuss = create(:creator, name: "Dr Seuss")
      bats = create(:collection, name: "Chiroptera")
      create(:model, name: "cat in the hat", tag_list: ["dog", "log", "frog", "cat"], creator: seuss, notes: "lorem ipsum", caption: nil)
      create(:model, name: "hat on the cat", tag_list: ["dog"], creator: seuss, notes: nil, caption: "dolor sit amet")
      create(:model, name: "bat on a mat", tag_list: ["log"], collection: bats, notes: nil, caption: nil)
      model = create(:model, name: "bat on a hat", tag_list: ["frog"], collection: bats, notes: nil, caption: nil)
      create(:model_file, filename: "big_hat.stl", model: model)
    end

    it "searches for a simple term" do
      expect(service.search("cat").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat")
    end

    it "searches for term which match a tag" do
      expect(service.search("dog").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat")
    end

    it "searches in creator names" do
      expect(service.search("seuss").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat")
    end

    it "searches in collection names" do
      expect(service.search("chiro").pluck(:name)).to contain_exactly("bat on a mat", "bat on a hat")
    end

    it "searches for results with any of the specified terms" do
      expect(service.search("cat or in or the or hat").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat", "bat on a hat")
    end

    it "searches for results containing two unquoted terms" do
      expect(service.search("the hat").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat")
    end

    it "searches for results containing the exact quoted term" do
      expect(service.search('"the hat"').pluck(:name)).to contain_exactly("cat in the hat")
    end

    it "searches for results which don't have an excluded term" do
      expect(service.search("hat and not cat").pluck(:name)).to contain_exactly("bat on a hat")
    end

    it "searches for AND combination of exclusions" do
      expect(service.search("not cat and not hat").pluck(:name)).to contain_exactly("bat on a mat")
    end

    it "searches for OR combination of exclusions" do
      expect(service.search("not cat or not hat").pluck(:name)).to contain_exactly("bat on a mat", "bat on a hat")
    end

    it "searches for complex combinations" do
      expect(service.search("(cat or hat) and not on").pluck(:name)).to contain_exactly("cat in the hat")
    end

    it "searches for other complex combinations" do
      expect(service.search("(cat or bat) and hat").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat", "bat on a hat")
    end

    it "searches for results which have all the words" do
      expect(service.search("cat hat").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat")
    end

    it "searches for results which have a specific tag" do
      expect(service.search("hat tag=cat").pluck(:name)).to contain_exactly("cat in the hat")
    end

    it "searches for results which don't have the specified tag" do
      expect(service.search("bat tag != frog").pluck(:name)).to contain_exactly("bat on a mat")
    end

    it "finds results which have a required word and a required tag" do
      expect(service.search("on tag=frog").pluck(:name)).to contain_exactly("bat on a hat")
    end

    it "finds results with a combination of tags" do
      expect(service.search("tag=frog tag=dog").pluck(:name)).to contain_exactly("cat in the hat")
    end

    it "finds results with an OR combination of tags" do
      expect(service.search("tag=frog or tag=dog").pluck(:name)).to contain_exactly("cat in the hat", "bat on a hat", "hat on the cat")
    end

    it "search specifically by creator name" do
      expect(service.search("hat creator~dr").pluck(:name)).to contain_exactly("cat in the hat", "hat on the cat")
    end

    it "filter specifically by collection name" do
      expect(service.search("hat collection~chiro").pluck(:name)).to contain_exactly("bat on a hat")
    end

    it "searches in notes if specified" do
      expect(service.search("description ~ lorem").pluck(:name)).to contain_exactly("cat in the hat")
    end

    it "searches in captions" do
      expect(service.search("dolor").pluck(:name)).to contain_exactly("hat on the cat")
    end

    it "searches in model filenames if specified" do
      expect(service.search("filename ~ big").pluck(:name)).to contain_exactly("bat on a hat")
    end
  end

  context "with indexing controls" do
    let!(:local_indexable) { create(:model, name: "test local indexable", indexable: "yes") }
    let!(:local_non_indexable) { create(:model, name: "test local nonindexable", indexable: "no") }
    let!(:remote_indexable) { create(:model, :remote, name: "test remote indexable", indexable: "yes") }
    let!(:remote_non_indexable) { create(:model, :remote, name: "test remote nonindexable", indexable: "no") }

    it "matches local models which are marked as indexable" do
      expect(service.search("test")).to include local_indexable
    end

    it "matches local models which are marked as non-indexable" do
      expect(service.search("test")).to include local_non_indexable
    end

    it "matches remote models which are marked as indexable" do
      expect(service.search("test")).to include remote_indexable
    end

    it "doesn't match remote models which are marked as non-indexable" do
      expect(service.search("test")).not_to include remote_non_indexable
    end
  end
end
