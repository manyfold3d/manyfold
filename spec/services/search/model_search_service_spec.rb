require "rails_helper"

RSpec.describe Search::ModelSearchService do
  subject(:service) { described_class.new(Model) }

  before do
    seuss = create(:creator, name: "Dr Seuss")
    bats = create(:collection, name: "Chiroptera")
    create(:model, name: "cat in the hat", tag_list: ["dog", "log", "frog", "cat"], creator: seuss)
    create(:model, name: "hat on the cat", tag_list: ["dog"], creator: seuss)
    create(:model, name: "bat on a mat", tag_list: ["log"], collection: bats)
    create(:model, name: "bat on a hat", tag_list: ["frog"], collection: bats)
  end

  it "searches for a simple term" do
    expect(service.search("cat").pluck(:name)).to eq [
      "cat in the hat",
      "hat on the cat"
    ]
  end

  it "searches for term which match a tag" do
    expect(service.search("dog").pluck(:name)).to eq [
      "cat in the hat",
      "hat on the cat"
    ]
  end

  it "searches in creator names" do
    expect(service.search("seuss").pluck(:name)).to eq [
      "cat in the hat",
      "hat on the cat"
    ]
  end

  it "searches in collection names" do
    expect(service.search("chiroptera").pluck(:name)).to eq [
      "bat on a mat",
      "bat on a hat"
    ]
  end

  it "searches for results with any of the specified terms" do
    expect(service.search("cat or in or the or hat").pluck(:name)).to eq [
      "cat in the hat",
      "hat on the cat",
      "bat on a hat"
    ]
  end

  it "searches for results containing two unquoted terms" do
    expect(service.search("the hat").pluck(:name)).to eq [
      "cat in the hat",
      "hat on the cat"
    ]
  end

  it "searches for results containing the exact quoted term" do
    expect(service.search('"the hat"').pluck(:name)).to eq [
      "cat in the hat"
    ]
  end

  it "searches for results which don't have an excluded term" do
    expect(service.search("hat and not cat").pluck(:name)).to eq [
      "bat on a hat"
    ]
  end

  it "searches for AND combination of exclusions" do
    expect(service.search("not cat and not hat").pluck(:name)).to eq [
      "bat on a mat"
    ]
  end

  it "searches for OR combination of exclusions" do
    expect(service.search("not cat or not hat").pluck(:name)).to eq [
      "bat on a mat",
      "bat on a hat"
    ]
  end

  it "searches for complex combinations" do
    expect(service.search("(cat or hat) and not on").pluck(:name)).to eq [
      "cat in the hat"
    ]
  end

  it "searches for other complex combinations" do
    expect(service.search("(cat or hat) and on").pluck(:name)).to eq [
      "hat on the cat",
      "bat on a hat"
    ]
  end

  it "searches for results which have all the words" do
    expect(service.search("hat on").pluck(:name)).to eq [
      "hat on the cat",
      "bat on a hat"
    ]
  end

  it "searches for results which have a specific tag" do
    expect(service.search("hat tag=cat").pluck(:name)).to eq [
      "cat in the hat"
    ]
  end

  it "searches for results which don't have the specified tag" do
    expect(service.search("on tag != frog").pluck(:name)).to eq [
      "hat on the cat",
      "bat on a mat"
    ]
  end

  it "finds results which have a required word and a required tag" do
    expect(service.search("on tag=frog").pluck(:name)).to eq [
      "bat on a hat"
    ]
  end

  it "finds results with a combination of tags" do
    expect(service.search("tag=frog tag=dog").pluck(:name)).to eq [
      "cat in the hat"
    ]
  end

  it "finds results with an OR combination of tags" do
    expect(service.search("tag=frog or tag=dog").pluck(:name)).to eq [
      "cat in the hat",
      "bat on a hat",
      "hat on the cat"
    ]
  end
end
