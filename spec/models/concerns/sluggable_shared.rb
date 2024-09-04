shared_examples "Sluggable" do

  it "automatically generates a slug from the name" do
    thing = create(described_class.name.parameterize.to_sym, name: "Spın̈al Tap")
    expect(thing.slug).to eq "spin-al-tap"
  end
end
