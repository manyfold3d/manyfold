require 'rails_helper'

RSpec.describe Model, type: :model do

  it "is not valid without a path" do
    expect(build :model, path: nil).not_to be_valid
  end

  it "is not valid without a name" do
    expect(build :model, name: nil).not_to be_valid
  end

  it "is not valid without being part of a library" do
    expect(build :model, library: nil).not_to be_valid
  end

  it "is valid if it has a path, name and library" do
    expect(build :model).to be_valid
  end

end
