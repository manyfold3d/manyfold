require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::CheckAllJob do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "queues up integrity and analysis jobs for all models and files" do
    thing = create(:model, path: "model_one")
    create(:model_file, filename: "missing.stl", model: thing)
    expect { described_class.perform_now }.to(
      have_enqueued_job(Scan::CheckModelIntegrityJob).once.and(have_enqueued_job(Scan::AnalyseModelFileJob).once)
    )
  end
end
