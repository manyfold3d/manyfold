require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::CreateModelJob do
  let(:library) { create(:library) }

  it "creates a single model" do
    expect { described_class.perform_now(library.id, "model") }.to change(Model, :count).from(0).to(1)
  end

  it "creates model in library" do
    described_class.perform_now(library.id, "model")
    expect(library.models.count).to be 1
  end

  it "sets correct path in new model" do
    described_class.perform_now(library.id, "model")
    expect(Model.first.path).to eql "model"
  end

  it "queues model up for a full scan" do
    described_class.perform_now(library.id, "model")
    expect(ModelScanJob).to have_been_enqueued.with(Model.first.id, include_all_subfolders: false).once
  end

  it "queues model up for a full scan including subfolders" do
    described_class.perform_now(library.id, "model", include_all_subfolders: true)
    expect(ModelScanJob).to have_been_enqueued.with(Model.first.id, include_all_subfolders: true).once
  end
end
