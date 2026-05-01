shared_examples "Sluggable" do
  it "automatically generates a slug from the name on creation" do
    thing = create(described_class.name.parameterize.to_sym, name: "Spın̈al Tap")
    expect(thing.slug).to eq "spin-al-tap"
  end

  it "automatically generates a slug from the name if nil" do
    thing = create(described_class.name.parameterize.to_sym, name: "Old Name")
    thing.update_columns slug: nil # rubocop:disable Rails/SkipsModelValidations
    expect { thing.update name: "New Name" }.to change(thing, :slug).from(nil).to("new-name")
  end

  it "doesn't generate slug if name isn't changed" do
    thing = create(described_class.name.parameterize.to_sym, name: "Old Name")
    thing.update_columns slug: nil # rubocop:disable Rails/SkipsModelValidations
    expect { thing.update(updated_at: Time.zone.now) }.not_to change(thing, :slug)
  end

  it "saves slug when manually set" do
    thing = create(described_class.name.parameterize.to_sym, name: "Old Name")
    expect { thing.update slug: "new-slug" }.to change(thing, :slug).from("old-name").to("new-slug")
  end

  it "updates slug from name when changed" do
    thing = create(described_class.name.parameterize.to_sym, name: "Old Name")
    expect { thing.update name: "New Name" }.to change(thing, :slug).from("old-name").to("new-name")
  end

  it "uses manual slug when name and slug are both changed" do
    thing = create(described_class.name.parameterize.to_sym, name: "Old Name")
    expect { thing.update name: "New Name", slug: "new-slug" }.to change(thing, :slug).from("old-name").to("new-slug")
  end
end
