require "rails_helper"

RSpec.describe LibraryScanJob do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:library) do
    create(:library, path: Rails.root.join("spec/fixtures/library"))
  end

  it "can scan a library directory" do
    expect { described_class.perform_now(library) }.to change { library.models.count }.to(4)
    expect(library.models.map(&:name)).to contain_exactly("Model One", "Model Two", "Nested Model", "Thingiverse Model")
    expect(library.models.map(&:path)).to contain_exactly("/model_one", "/subfolder/model_two", "/model_one/nested_model", "/thingiverse_model")
  end

  it "queues up model scans" do
    expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(4).times
  end

  it "only scans models with changes on rescan" do
    model_one = create(:model, path: "model_one", library: library)
    ModelScanJob.perform_now(model_one)
    # TODO maybe: not getting to nested models now, just including them
    expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(2).times
  end

  it "flags models with no files as problems" do
    lib = create(:library, path: File.join("/", "tmp"))
    create(:model, library: lib, path: "missing")
    expect { described_class.perform_now(lib) }.to change(Problem, :count).from(0).to(1)
  end
end
