require "rails_helper"

RSpec.describe Scan::CheckModelJob do
  let!(:thing) { create(:model, path: "model_one") }
  let!(:file) { create(:model_file, model: thing) }

  it "queues up model file scan job" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(Scan::Model::AddNewFilesJob).with(thing.id, include_all_subfolders: false).once
    )
  end

  it "queues up analysis jobs for all model files" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(Analysis::AnalyseModelFileJob).with(file.id).once
    )
  end

  it "raises exception if model ID is not found" do
    expect { described_class.perform_now(nil) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
