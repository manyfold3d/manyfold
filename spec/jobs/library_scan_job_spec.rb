require "rails_helper"

RSpec.describe LibraryScanJob, type: :job do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:library) do
    create(:library, path: Rails.root.join("spec", "fixtures", "library"))
  end

  it "generates a case-insensitive pattern for files" do
    expect(LibraryScanJob.file_pattern).to include "*.{stl,STL"
  end

  it "can scan a library directory" do
    expect { LibraryScanJob.perform_now(library) }.to change { library.models.count }.to(4)
    expect(library.models.map(&:name)).to match_array ["Model One", "Model Two", "Nested Model", "Thingiverse Model"]
    expect(library.models.map(&:path)).to match_array ["/model_one", "/subfolder/model_two", "/model_one/nested_model", "/thingiverse_model"]
  end

  it "queues up model scans" do
    expect { LibraryScanJob.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(4).times
  end

  it "only scans models with changes on rescan" do
    model_one = create(:model, path: "model_one", library: library)
    ModelScanJob.perform_now(model_one)
    expect { LibraryScanJob.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(3).times
  end

  it "flags models with no files as problems" do
    lib = create(:library, path: File.join("/", "tmp"))
    create(:model, library: lib, path: "missing")
    expect { LibraryScanJob.perform_now(lib) }.to change { Problem.count }.from(0).to(1)
  end
end
