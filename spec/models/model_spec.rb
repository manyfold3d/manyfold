require "rails_helper"

RSpec.describe Model, type: :model do
  it "is not valid without a path" do
    expect(build(:model, path: nil)).not_to be_valid
  end

  it "is not valid without a name" do
    expect(build(:model, name: nil)).not_to be_valid
  end

  it "is not valid without being part of a library" do
    expect(build(:model, library: nil)).not_to be_valid
  end

  it "is valid if it has a path, name and library" do
    expect(build(:model)).to be_valid
  end

  it "has many parts" do
    expect(build(:model).parts).to eq []
  end

  it "must have a unique path within its library" do
    library = create(:library, path: "/library")
    create(:model, library: library, path: "model")
    expect(build(:model, library: library, path: "model")).not_to be_valid
  end

  it "can have the same path as a model in a different library" do
    library1 = create(:library, path: "/library1")
    create(:model, library: library1, path: "model")
    library2 = create(:library, path: "/library2")
    expect(build(:model, library: library2, path: "model")).to be_valid
  end
end
