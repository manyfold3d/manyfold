require "rails_helper"

RSpec.describe Library, type: :model do
  before :each do
    allow(File).to receive(:exist?).with("/library1").and_return(true)
  end

  it "is not valid without a path" do
    expect(build(:library, path: nil)).not_to be_valid
  end

  it "is valid if a path is specified" do
    expect(build(:library, path: "/library1")).to be_valid
  end

  it "has many models" do
    expect(build(:library).models).to eq []
  end

  it "must have a unique path" do
    create(:library, path: "/library1")
    expect(build(:library, path: "/library1")).not_to be_valid
  end
end
