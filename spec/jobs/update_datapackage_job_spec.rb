require "rails_helper"

RSpec.describe UpdateDatapackageJob do
  let(:model) { create(:model) }

  it "raises exception if model ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "creates datapackage file if there isn't one already" do
    expect { described_class.perform_now(model.id) }.to change { ModelFile.including_special.count }.from(0).to(1)
  end

  it "uses existing datapackage file one already exists" do
    described_class.perform_now(model.id)
    expect { described_class.perform_now(model.id) }.not_to change { ModelFile.including_special.count }
  end

  it "updates datapackage file when model changes" do
    described_class.perform_now(model.id)
    model.update! name: "Changed"
    described_class.perform_now(model.id)
    # Load JSON file
    json = JSON.parse(model.model_files.including_special.find_by(filename: "datapackage.json").attachment.read)
    expect(json["title"]).to eq "Changed"
  end
end
