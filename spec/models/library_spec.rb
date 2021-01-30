require 'rails_helper'

RSpec.describe Library, type: :model do

  it "is not valid without a path" do
    expect(Library.new(path: nil)).not_to be_valid
  end

  it "is valid if a path is specified" do
    expect(Library.new(path: "/library")).to be_valid
  end

end
