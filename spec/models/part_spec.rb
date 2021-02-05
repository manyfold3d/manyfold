require "rails_helper"

RSpec.describe Part, type: :model do
  it "is not valid without a filename" do
    expect(build(:part, filename: nil)).not_to be_valid
  end

  it "is not valid without being part of a model" do
    expect(build(:part, model: nil)).not_to be_valid
  end

  it "is valid if it has a filename and model" do
    expect(build(:part)).to be_valid
  end
end
