require "rails_helper"
require "support/mock_directory"

RSpec.describe Scan::DetectFilesystemChangesJob do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  context "with files in various folders" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/part_2.obj",
        "subfolder/model_two/part_one.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable

    it "can scan a library directory" do
      expect { described_class.perform_now(library.id) }.to change { library.models.count }.to(2)
      expect(library.models.map(&:path)).to contain_exactly("model_one", "subfolder/model_two")
    end

    it "queues up model scans" do
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(ModelScanJob).exactly(2).times
    end

    it "only scans models with changes on rescan" do
      model_one = create(:model, path: "model_one", library: library)
      ModelScanJob.perform_now(model_one.id)
      expect { described_class.perform_now(library.id) }.to have_enqueued_job(ModelScanJob).exactly(1).times
    end
  end

  context "with nested models" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/nested/part_2.obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "pulls out nested model as separate" do
      expect { described_class.perform_now(library.id) }.to change { library.models.count }.to(2)
      expect(library.models.map(&:path)).to contain_exactly("model_one", "model_one/nested")
    end
  end

  context "with a thingiverse-style model folder" do
    around do |ex|
      MockDirectory.create([
        "thingiverse_model/files/part_one.stl",
        "thingiverse_model/images/preview.png",
        "thingiverse_model/README.txt"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "understands that it's a single model" do
      expect { described_class.perform_now(library.id) }.to change { library.models.count }.to(1)
      expect(library.models.map(&:path)).to contain_exactly("thingiverse_model")
    end
  end

  context "with model folders that contain some common subfolders" do
    around do |ex|
      MockDirectory.create([
        "model/presupported/part_one.stl",
        "model/unsupported/part_one.stl",
        "model/supported/part_one.stl",
        "model/parts/part_one.stl",
        "model/files/part_one.stl",
        "model/images/part_one.png"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "understands that it's a single model" do
      expect { described_class.perform_now(library.id) }.to change { library.models.count }.to(1)
      expect(library.models.map(&:path)).to contain_exactly("model")
    end
  end

  context "with model folders that contain some common subfolders with mixed case" do
    around do |ex|
      MockDirectory.create([
        "model/Presupported/part_one.stl",
        "model/UnSupported/part_one.stl",
        "model/Supported/part_one.stl",
        "model/Parts/part_one.stl",
        "model/Files/part_one.stl",
        "model/Images/part_one.png"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "ignores case and filters out subfolders correctly" do
      expect { described_class.perform_now(library.id) }.to change { library.models.count }.to(1)
      expect(library.models.map(&:path)).to contain_exactly("model")
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

    # rubocop:todo RSpec/InstanceVariable

    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "does not include directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).not_to include File.join(library.path, "wrong.stl")
    end

    it "does include files within directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "wrong.stl/file.stl")
    end
  end

  context "with a case sensitive filesystem", :case_sensitive do
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

    # rubocop:todo RSpec/InstanceVariable

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
