require "rails_helper"

RSpec.describe Creator do
  it "automatically generates a slug from the name" do
    creator = create(:creator, name: "Spın̈al Tap")
    expect(creator.slug).to eq "spin-al-tap"
  end

  it "generates an empty slug when name is nil" do
    creator = create(:creator, name: nil)
    expect(creator.slug).to eq ""
  end

  it "removes non-alphanumeric characters from slug" do
    creator = create(:creator, name: "Spın̈al Tap!")
    expect(creator.slug).to eq "spin-al-tap"
  end
end
