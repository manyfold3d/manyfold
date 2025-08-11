require "rails_helper"

RSpec.describe UpdateDatapackageJob do
  let(:model) { create(:model) }
  let(:datapackage_json) { model.datapackage_content }

  it "raises exception if model ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "when creating first datapackage" do
    it "creates file if there isn't one already" do
      expect { described_class.perform_now(model.id) }.to change(ModelFile, :count).from(0).to(1)
    end

    it "doesn't include datapackage in resources" do
      described_class.perform_now(model.id)
      expect(datapackage_json["resources"].pluck("path")).not_to include("datapackage.json")
    end
  end

  context "when updating a model with a datapackage" do
    before do
      # Make initial datapackage
      described_class.perform_now(model.id)
    end

    it "uses existing file if one already exists" do
      expect { described_class.perform_now(model.id) }.not_to change(ModelFile, :count)
    end

    it "doesn't include datapackage in resources" do
      expect(datapackage_json["resources"].pluck("path")).not_to include("datapackage.json")
    end
  end

  it "updates datapackage file when model changes" do
    described_class.perform_now(model.id)
    model.update! name: "Changed"
    described_class.perform_now(model.id)
    expect(datapackage_json["title"]).to eq "Changed"
  end
end
