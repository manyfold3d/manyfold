require "rails_helper"

RSpec.describe Library do
  around do |ex|
    MockDirectory.create([]) do |path|
      @library_path = path
      ex.run
    end
  end

  it "is not valid without a path" do
    expect(build(:library, path: nil)).not_to be_valid
  end

  it "is valid if a path is specified" do
    expect(build(:library, path: @library_path)).to be_valid # rubocop:todo RSpec/InstanceVariable
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
    create(:library, path: @library_path) # rubocop:todo RSpec/InstanceVariable
    expect(build(:library, path: @library_path)).not_to be_valid # rubocop:todo RSpec/InstanceVariable
  end
end
