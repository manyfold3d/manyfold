require "rails_helper"
require "support/mock_directory"

RSpec.describe LibraryScanJob do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  context "with fixtures" do
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
      expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(3).times
    end

    it "flags models with no files as problems" do
      lib = create(:library, path: File.join("/", "tmp"))
      create(:model, library: lib, path: "missing")
      expect { described_class.perform_now(lib) }.to change(Problem, :count).from(0).to(1)
    end
  end

  context "with folders that look like filenames" do
    around do |ex|
      MockDirectory.create([
        "wrong.stl/file.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "does not include directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).not_to include File.join(library.path, "wrong.stl")
    end

    it "does include files within directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "wrong.stl/file.stl")
    end
  end

  context "with a case sensitive filesystem", case_sensitive: true do
    around do |ex|
      MockDirectory.create([
        "model/file.obj",
        "model/file.OBJ",
        "model/file.Obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "detects lowercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.obj")
    end

    it "detects uppercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.OBJ")
    end

    it "detects mixed case file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.Obj")
    end
  end
end
