require "rails_helper"

RSpec.describe Collection do
  it "automatically generates a slug from the name" do
    collection = create(:collection, name: "Spın̈al Tap")
    expect(collection.slug).to eq "spin-al-tap"
  end

  it "adds a model to the collection" do
    collection = create(:collection)
    model = create(:model)
    collection.add_model(model)
    expect(collection.models).to include(model)
  end

  it "removes a model from the collection" do
    collection = create(:collection)
    model = create(:model)
    collection.add_model(model)
    collection.remove_model(model)
    expect(collection.models).not_to include(model)
  end
end
