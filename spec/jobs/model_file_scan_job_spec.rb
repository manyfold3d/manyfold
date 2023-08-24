require "rails_helper"

RSpec.describe ModelFileScanJob do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:file) { create(:model_file) }
  let(:supported_file) { create(:model_file, filename: "file1_supported.stl") }

  it "detects if file is presupported" do
    described_class.perform_now(supported_file.id)
    supported_file.reload
    expect(supported_file.presupported).to be true
  end

  it "detects if file is unsupported" do
    described_class.perform_now(file.id)
    file.reload
    expect(file.presupported).to be false
  end

  it "queues analysis job" do
    expect { described_class.perform_now(file.id) }.to have_enqueued_job(Scan::AnalyseModelFileJob).once
  end
end
