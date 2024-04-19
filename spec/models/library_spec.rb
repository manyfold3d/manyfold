require "rails_helper"

RSpec.describe Library do
  before do
    allow(File).to receive(:exist?).with("/library1").and_return(true)
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with("/library1").and_return(["/library1"])
    allow(File).to receive(:exist?).with("/nope").and_return(false)
  end

  it "is not valid without a path" do
    expect(build(:library, path: nil)).not_to be_valid
  end

  it "is valid if a path is specified" do
    expect(build(:library, path: "/library1")).to be_valid
  end

  it "is invalid if a bad path is specified" do # rubocop:todo RSpec/MultipleExpectations
    l = build(:library, path: "/nope")
    expect(l).not_to be_valid
    expect(l.errors[:path].first).to eq "could not be found on disk"
  end

  it "has many models" do
    expect(build(:library).models).to eq []
  end

  it "must have a unique path" do
    create(:library, path: "/library1")
    expect(build(:library, path: "/library1")).not_to be_valid
  end
end
