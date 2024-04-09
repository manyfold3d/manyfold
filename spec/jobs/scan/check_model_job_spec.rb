require "rails_helper"

RSpec.describe Scan::CheckModelJob do
  let!(:thing) { create(:model, path: "model_one") }
  let!(:file) { create(:model_file, model: thing) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "queues up model file scan job" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(ModelScanJob).with(thing.id).once
    )
  end

  it "does not queue up model file scan job if scan parameter is false" do
    expect { described_class.perform_now(thing.id, scan: false) }.not_to(
      have_enqueued_job(ModelScanJob)
    )
  end

  it "queues up model integrity check job" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(Scan::CheckModelIntegrityJob).with(thing.id).once
    )
  end

  it "queues up analysis jobs for all model files" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(Analysis::AnalyseModelFileJob).with(file.id).once
    )
  end

  it "fails silently if model ID is not found" do
    expect { described_class.perform_now(nil) }.not_to raise_error
  end

end
