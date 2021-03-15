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

  it "must have a unique filename within its model" do
    model = create(:model, path: "model")
    create(:part, model: model, filename: "part.stl")
    expect(build(:part, model: model, filename: "part.stl")).not_to be_valid
  end

  it "can have the same filename as a part in a different model" do
    library = create(:library)
    model1 = create(:model, library: library, path: "model1")
    create(:part, model: model1, filename: "part.stl")
    model2 = create(:model, library: library, path: "model2")
    expect(build(:part, model: model2, filename: "part.stl")).to be_valid
  end
end
