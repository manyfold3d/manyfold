require "rails_helper"

RSpec.describe Library, type: :model do
  it "is not valid without a path" do
    expect(build(:library, path: nil)).not_to be_valid
  end

  it "is valid if a path is specified" do
    expect(build(:library, path: "/library")).to be_valid
  end

  it "has many models" do
    expect(build(:library).models).to eq []
  end
end
