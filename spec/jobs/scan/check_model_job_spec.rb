require "rails_helper"

RSpec.describe Scan::CheckModelJob do
  let!(:thing) { create(:model, path: "model_one") }
  let!(:file) { create(:model_file, model: thing) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "should queue up model file scan job" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(ModelScanJob).with(thing.id).once
    )
  end

  it "should not queue up model file scan job if scan parameter is false" do
    expect { described_class.perform_now(thing.id, scan: false) }.not_to(
      have_enqueued_job(ModelScanJob)
    )
  end

  it "should queue up model integrity check job" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(Scan::CheckModelIntegrityJob).with(thing.id).once
    )
  end

  it "should queue up analysis jobs for all model files" do
    expect { described_class.perform_now(thing.id) }.to(
      have_enqueued_job(Scan::AnalyseModelFileJob).with(file.id).once
    )
  end

end
