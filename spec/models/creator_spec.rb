require "rails_helper"

RSpec.describe Creator do
  it "automatically generates a slug from the name" do
    creator = create(:creator, name: "Spın̈al Tap")
    expect(creator.slug).to eq "spinal-tap"
  end
end
