require "rails_helper"

RSpec.describe Collection do
  it "automatically generates a slug from the name" do
    collection = create(:collection, name: "Spın̈al Tap")
    expect(collection.slug).to eq "spin-al-tap"
  end
end
